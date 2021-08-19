//
//  FFmpegManager.cpp
//  Runner
//
//  Created by KK Systems on 2021/08/01.
//

#define __STDC_CONSTANT_MACROS
#define __STDC_LIMIT_MACROS

#include "FFmpegManager.hpp"

#include <deque>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswresample/swresample.h>

#include <libavutil/audio_fifo.h>
}

int64_t pts = 0;

class Resampler
{
public:
	Resampler(const AVCodecContext& inputCodecContext, const AVCodecContext& outputCodecContext);
	~Resampler(void);

	int convertSamples(const uint8_t** inputData, uint8_t** convertedData, const int frameSize);

private:
	SwrContext* context;
};

Resampler::Resampler(const AVCodecContext& inputCodecContext, const AVCodecContext& outputCodecContext)
{
	context = swr_alloc_set_opts(nullptr,
								 av_get_default_channel_layout(outputCodecContext.channels),
								 outputCodecContext.sample_fmt,
								 outputCodecContext.sample_rate,
								 av_get_default_channel_layout(inputCodecContext.channels),
								 inputCodecContext.sample_fmt,
								 inputCodecContext.sample_rate,
								 0, nullptr);
	
	if (!context) {
		throw std::runtime_error("Could not allocate resample context");
	}

	if (swr_init(context) < 0) {
		swr_free(&context);
		throw std::runtime_error("Could not open resample context");
	}
}

Resampler::~Resampler(void)
{
	if (context != nullptr) {
		swr_free(&context);
	}
}

int Resampler::convertSamples(const uint8_t **inputData, uint8_t **convertedData, const int frameSize)
{
	int status = 0;

	if ((status = swr_convert(context, convertedData, frameSize, inputData, frameSize)) < 0) {
		return status;
	}
	
	return 0;
}

class AudioFifo
{
public:
	AudioFifo(const AVCodecContext &outputCodecContext);

	int addSamples(uint8_t **inputSamples, const int frame_size);
	int readSamples(uint8_t **outputSamples, const int frame_size);
	int size() const;

private:
	AVAudioFifo *fifo;
};

AudioFifo::AudioFifo(const AVCodecContext &outputCodecContext)
{
	if (!(fifo = av_audio_fifo_alloc(outputCodecContext.sample_fmt,
									 outputCodecContext.channels, 1))) {
		throw std::runtime_error("Could not allocate FIFO");
	}
}

int AudioFifo::addSamples(uint8_t **inputSamples, const int frame_size) {
	int error;

	if ((error = av_audio_fifo_realloc(fifo, av_audio_fifo_size(fifo) + frame_size)) < 0) {
		printf("Could not reallocate FIFO\n");
		return error;
	}

	if (av_audio_fifo_write(fifo, reinterpret_cast<void **>(inputSamples), frame_size) < frame_size) {
		printf("Could not write data to FIFO\n");
		return AVERROR_EXIT;
	}

	return 0;
}

int AudioFifo::readSamples(uint8_t **outputSamples, const int frame_size) {
	if (av_audio_fifo_read(fifo, reinterpret_cast<void **>(outputSamples), frame_size) < frame_size) {
		printf("Could not write data to FIFO\n");
		return AVERROR_EXIT;
	}

	return 0;
}

int AudioFifo::size() const {
	return av_audio_fifo_size(fifo);
}

int getAudioStream(const AVFormatContext *formatContext, AVStream **audioStream)
{
	for (int i = 0; i < (int)formatContext->nb_streams; ++i) {
		if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
			*audioStream = formatContext->streams[i];
			return 0;
		}
	}
	
	return AVERROR_STREAM_NOT_FOUND;
}

int openInputFile(const std::string& filePath,
				  AVFormatContext **inputFormatCtx,
				  AVCodecContext **inputCodecCtx)
{
	int status = 0;
	AVCodecContext *codecCtx = nullptr;
	const AVCodec *inputCodec;
	AVStream *audioStream = nullptr;

	if ((status = avformat_open_input(inputFormatCtx, filePath.c_str(), nullptr, nullptr)) != 0) {
		printf("avformat_open_input failed\n");
		*inputFormatCtx = nullptr;
		return status;
	}

	if ((status = avformat_find_stream_info(*inputFormatCtx, nullptr)) != 0) {
		printf("avformat_find_stream_info failed\n");
		avformat_close_input(inputFormatCtx);
		return status;
	}

	if ((status = getAudioStream(*inputFormatCtx, &audioStream)) != 0) {
		printf("getAudioStream failed\n");
		avformat_close_input(inputFormatCtx);
		return status;
	}

	if (!(inputCodec = avcodec_find_decoder(audioStream->codecpar->codec_id))) {
		printf("avcodec_find_decoder failed\n");
		avformat_close_input(inputFormatCtx);
		status = AVERROR_DECODER_NOT_FOUND;
		return status;
	}

	if (!(codecCtx = avcodec_alloc_context3(inputCodec))) {
		printf("avcodec_alloc_context3 failed\n");
		avformat_close_input(inputFormatCtx);
		status = AVERROR_UNKNOWN;
		return status;
	}

	if ((status = avcodec_parameters_to_context(codecCtx, audioStream->codecpar)) != 0) {
		printf("avcodec_parameters_to_context failed\n");
		avcodec_free_context(&codecCtx);
		avformat_close_input(inputFormatCtx);
		return status;
	}

	if ((status = avcodec_open2(codecCtx, inputCodec, nullptr)) != 0) {
		printf("avcodec_open2 failed\n");
		avcodec_free_context(&codecCtx);
		avformat_close_input(inputFormatCtx);
		return status;
	}

	*inputCodecCtx = codecCtx;
	
	return status;
}

int openOutputFile(const std::string& filePath,
				   AVCodecContext	*inputCodecCtx,
				   AVFormatContext	**outputFormatCtx,
				   AVCodecContext	**outputCodecCtx)
{
	int status = 0;
	AVCodecContext	*avCtx = nullptr;
	AVIOContext		*ioCtx = nullptr;
	AVCodec			*outputCodec = nullptr;
	AVStream		*stream = nullptr;

	if ((status = avio_open(&ioCtx, filePath.c_str(), AVIO_FLAG_WRITE)) < 0) {
		printf("avio_open failed\n");
		return status;
	}

	if (!(*outputFormatCtx = avformat_alloc_context())) {
		printf("Could not allocate output format context\n");
		status = AVERROR(ENOMEM);
		return status;
	}

	(*outputFormatCtx)->pb = ioCtx;

	if (!((*outputFormatCtx)->oformat = av_guess_format(nullptr, filePath.c_str(), nullptr))) {
		printf("av_guess_format failed\n");
		goto cleanup;
	}

	if (!((*outputFormatCtx)->url = av_strdup(filePath.c_str()))) {
		printf("av_strdup failed\n");
		goto cleanup;
	}

	if (!(outputCodec = avcodec_find_encoder(AV_CODEC_ID_AAC))) {
		printf("avcodec_find_encoder failed\n");
		goto cleanup;
	}

	if (!(stream = avformat_new_stream(*outputFormatCtx, outputCodec))) {
		printf("avformat_new_stream failed\n");
		status = AVERROR(ENOMEM);
		goto cleanup;
	}

	if (!(avCtx = avcodec_alloc_context3(outputCodec))) {
		printf("avcodec_alloc_context3 failed\n");
		status = AVERROR(ENOMEM);
		goto cleanup;
	}

	avCtx->channels			= 2;
	avCtx->channel_layout	= av_get_default_channel_layout(2);
	avCtx->sample_rate		= inputCodecCtx->sample_rate;
	avCtx->sample_fmt		= outputCodec->sample_fmts[0];
	avCtx->bit_rate			= 256000;

	avCtx->strict_std_compliance = FF_COMPLIANCE_EXPERIMENTAL;

	stream->time_base.den	= inputCodecCtx->sample_rate;
	stream->time_base.num	= 1;

	// generate global header when the format require it
	if ((*outputFormatCtx)->oformat->flags & AVFMT_GLOBALHEADER) {
		avCtx->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
	}

	if ((status = avcodec_open2(avCtx, outputCodec, nullptr)) < 0) {
		printf("avcodec_open2 failed\n");
		goto cleanup;
	}

	if ((status = avcodec_parameters_from_context(stream->codecpar, avCtx)) < 0) {
		printf("avcodec_parameters_from_context failed");
		goto cleanup;
	}

	*outputCodecCtx = avCtx;

	return status;

cleanup:
	avcodec_free_context(&avCtx);
	avio_closep(&(*outputFormatCtx)->pb);
	avformat_free_context(*outputFormatCtx);
	*outputFormatCtx = nullptr;

	return status < 0 ? status : AVERROR_EXIT;
}

int initPacket(AVPacket **packet)
{
	if (!(*packet = av_packet_alloc())) {
		printf("Could not allocate packet\n");
		return AVERROR(ENOMEM);
	}

	return 0;
}

int initInputFrame(AVFrame **frame)
{
	if (!(*frame = av_frame_alloc())) {
		printf("Could not allocate input frame\n");
		return AVERROR(ENOMEM);
	}

	return 0;
}

int decodeAudioFrame(AVFrame *frame,
					 AVFormatContext *inputFormatContext,
					 AVCodecContext *inputCodecContext,
					 bool &dataPresent, bool &finished)
{
	/* Packet used for temporary storage. */
	AVPacket *inputPacket;
	int error;

	error = initPacket(&inputPacket);
	if (error < 0)
		return error;

	/* Read one audio frame from the input file into a temporary packet. */
	if ((error = av_read_frame(inputFormatContext, inputPacket)) < 0) {
		/* If we are at the end of the file, flush the decoder below. */
		if (error == AVERROR_EOF)
			finished = true;
		else {
			printf("Could not read frame (error '%s')\n", av_err2str(error));
			goto cleanup;
		}
	}

	/* Send the audio frame stored in the temporary packet to the decoder.
	 * The input audio stream decoder is used to do this. */
	if ((error = avcodec_send_packet(inputCodecContext, inputPacket)) < 0) {
		printf("Could not send packet for decoding (error '%s')\n", av_err2str(error));
		goto cleanup;
	}

	/* Receive one frame from the decoder. */
	error = avcodec_receive_frame(inputCodecContext, frame);
	/* If the decoder asks for more data to be able to decode a frame,
	 * return indicating that no data is present. */
	if (error == AVERROR(EAGAIN)) {
		error = 0;
		goto cleanup;
	/* If the end of the input file is reached, stop decoding. */
	} else if (error == AVERROR_EOF) {
		finished = true;
		error = 0;
		goto cleanup;
	} else if (error < 0) {
		printf("Could not decode frame (error '%s')\n", av_err2str(error));
		goto cleanup;
	/* Default case: Return decoded data. */
	} else {
		dataPresent = true;
		goto cleanup;
	}

cleanup:
	av_packet_free(&inputPacket);
	return error;
}

int initConvertedSamples(uint8_t ***convertedInputSamples,
						   AVCodecContext *outputCodecContext,
						   int frameSize)
{
	int error;

	if (!(*convertedInputSamples = reinterpret_cast<uint8_t**>(calloc(outputCodecContext->channels, sizeof(**convertedInputSamples))))) {
		printf("Could not allocate converted input sample pointers\n");
		return AVERROR(ENOMEM);
	}

	if ((error = av_samples_alloc(*convertedInputSamples, nullptr,
								  outputCodecContext->channels,
								  frameSize,
								  outputCodecContext->sample_fmt, 0)) < 0) {
		printf("Could not allocate converted input samples (error '%s')\n", av_err2str(error));
		av_freep(&(*convertedInputSamples)[0]);
		free(*convertedInputSamples);
		return error;
	}
	return 0;
}

int convertSamples(const uint8_t **input_data,
				   uint8_t **converted_data, const int frame_size,
				   Resampler &resampler)
{
	int error;

	/* Convert the samples using the resampler. */
	if ((error = resampler.convertSamples(input_data, converted_data, frame_size)) < 0) {
		printf("Could not convert input samples (error '%s')\n", av_err2str(error));
		return error;
	}

	return 0;
}

int readDecodeConvertAndStore(AudioFifo &fifo,
							  AVFormatContext *inputFormatContext,
							  AVCodecContext *inputCodecContext,
							  AVCodecContext *outputCodecContext,
							  Resampler &resampler,
							  bool &finished)
{
	AVFrame *inputFrame = NULL;
	uint8_t **convertedInputSamples = NULL;
	bool dataPresent = false;
	int ret = AVERROR_EXIT;

	if (initInputFrame(&inputFrame)) {
		goto cleanup;
	}

	if (decodeAudioFrame(inputFrame, inputFormatContext, inputCodecContext, dataPresent, finished)) {
		goto cleanup;
	}

	if (finished) {
		ret = 0;
		goto cleanup;
	}

	if (dataPresent) {
		if (initConvertedSamples(&convertedInputSamples, outputCodecContext, inputFrame->nb_samples)) {
			goto cleanup;
		}

		if (convertSamples(const_cast<const uint8_t**>(reinterpret_cast<uint8_t**>(inputFrame->extended_data)),
						   convertedInputSamples, inputFrame->nb_samples, resampler)) {
			goto cleanup;
		}

		if (fifo.addSamples(convertedInputSamples, inputFrame->nb_samples)) {
			goto cleanup;
		}

		ret = 0;
	}

	ret = 0;

cleanup:
	if (convertedInputSamples) {
		av_freep(&convertedInputSamples[0]);
		free(convertedInputSamples);
	}
	av_frame_free(&inputFrame);

	return ret;
}

int initOutputFrame(AVFrame **frame,
					  AVCodecContext *output_codec_context,
					  int frame_size)
{
	int error;

	if (!(*frame = av_frame_alloc())) {
		printf("Could not allocate output frame\n");
		return AVERROR_EXIT;
	}

	(*frame)->nb_samples     = frame_size;
	(*frame)->channel_layout = output_codec_context->channel_layout;
	(*frame)->format         = output_codec_context->sample_fmt;
	(*frame)->sample_rate    = output_codec_context->sample_rate;

	if ((error = av_frame_get_buffer(*frame, 0)) < 0) {
		printf("Could not allocate output frame samples (error '%s')\n", av_err2str(error));
		av_frame_free(frame);
		return error;
	}

	return 0;
}

int encodeAudioFrame(AVFrame *frame,
					 AVFormatContext *outputFormatContext,
					 AVCodecContext *outputCodecContext,
					 bool &dataPresent)
{
	AVPacket *outputPacket;
	int error;

	error = initPacket(&outputPacket);
	if (error < 0)
		return error;

	if (frame) {
		frame->pts = pts;
		pts += frame->nb_samples;
	}

	error = avcodec_send_frame(outputCodecContext, frame);
	if (error == AVERROR_EOF) {
		error = 0;
		goto cleanup;
	} else if (error < 0) {
		printf("Could not send packet for encoding (error '%s')\n", av_err2str(error));
		goto cleanup;
	}

	error = avcodec_receive_packet(outputCodecContext, outputPacket);
	if (error == AVERROR(EAGAIN)) {
		error = 0;
		goto cleanup;
	} else if (error == AVERROR_EOF) {
		error = 0;
		goto cleanup;
	} else if (error < 0) {
		printf("Could not encode frame (error '%s')\n", av_err2str(error));
		goto cleanup;
	} else {
		dataPresent = true;
	}

	if (dataPresent &&
		(error = av_write_frame(outputFormatContext, outputPacket)) < 0) {
		printf("Could not write frame (error '%s')\n", av_err2str(error));
		goto cleanup;
	}

cleanup:
	av_packet_free(&outputPacket);
	return error;
}

int loadEncodeAndWrite(AudioFifo &fifo,
					   AVFormatContext *outputFormatContext,
					   AVCodecContext *outputCodecContext)
{
	AVFrame *outputFrame;
	const int frameSize = FFMIN(fifo.size(), outputCodecContext->frame_size);
	bool dataWritten = false;

	if (initOutputFrame(&outputFrame, outputCodecContext, frameSize))
		return AVERROR_EXIT;

	if (fifo.readSamples(reinterpret_cast<uint8_t**>(outputFrame->data), frameSize)) {
		printf("Could not read data from FIFO\n");
		av_frame_free(&outputFrame);
		return AVERROR_EXIT;
	}

	if (encodeAudioFrame(outputFrame, outputFormatContext,
						 outputCodecContext, dataWritten)) {
		av_frame_free(&outputFrame);
		return AVERROR_EXIT;
	}

	av_frame_free(&outputFrame);

	return 0;
}

int writeOutputFileHeader(AVFormatContext *output_format_context)
{
	int error;

	if ((error = avformat_write_header(output_format_context, NULL)) < 0) {
		fprintf(stderr, "Could not write output file header (error '%s')\n", av_err2str(error));
		return error;
	}

	return 0;
}

int writeOutputFileTrailer(AVFormatContext *outputFormatContext)
{
	int error;

	if ((error = av_write_trailer(outputFormatContext)) < 0) {
		printf("Could not write output file trailer (error '%s')\n", av_err2str(error));
		return error;
	}

	return 0;
}

FFmpegManager& FFmpegManager::getInstance()
{
	static FFmpegManager instance;
	return instance;
}

void FFmpegManager::convertFile(const std::string& inputPath, const std::string& outputPath, const ConvertingCallback callback)
{
	AVFormatContext *inputFormatContext = nullptr, *outputFormatContext = nullptr;
	AVCodecContext *inputCodecContext = nullptr, *outputCodecContext = nullptr;

	pts = 0;

	try {
		if (openInputFile(inputPath, &inputFormatContext, &inputCodecContext)) {
			throw std::runtime_error("ERROR_UNSUPPORTED_FILE");
		}

		if (openOutputFile(outputPath, inputCodecContext, &outputFormatContext, &outputCodecContext)) {
			throw std::runtime_error("ERROR_CANT_WRITE_FILE");
		}

		Resampler resampler(*inputCodecContext, *outputCodecContext);
		AudioFifo fifo(*outputCodecContext);

		if (writeOutputFileHeader(outputFormatContext)) {
			throw std::runtime_error("ERROR_FAILED_TO_WRITE_HEADER");
		}

		av_dict_copy(&outputFormatContext->metadata, inputFormatContext->metadata, AV_DICT_MULTIKEY);

		const int64_t duration = inputFormatContext->duration;

		while (true) {
			const int outputFrameSize = outputCodecContext->frame_size;
			bool finished = 0;

			while (!finished && fifo.size() < outputFrameSize) {
				if (readDecodeConvertAndStore(fifo, inputFormatContext,
											  inputCodecContext, outputCodecContext,
											  resampler, finished)) {
					throw std::runtime_error("ERROR_FAILED_TO_DECODE");
				}
			}

			while (fifo.size() >= outputFrameSize || (finished && fifo.size() > 0)) {
				if (loadEncodeAndWrite(fifo, outputFormatContext, outputCodecContext)) {
					throw std::runtime_error("ERROR_FAILED_TO_ENCODE");
				}
			}

			AVRational duration_base{.num = 1, .den = AV_TIME_BASE};
			(*callback)(av_rescale_q(pts, inputCodecContext->time_base, inputCodecContext->time_base),
						av_rescale_q(duration, duration_base, inputCodecContext->time_base));

			if (finished) {
				bool dataWritten;

				do {
					dataWritten = false;

					if (encodeAudioFrame(nullptr, outputFormatContext, outputCodecContext, dataWritten)) {
						throw std::runtime_error("ERROR_FAILED_TO_ENCODE");
					}
				} while (dataWritten);

				break;
			}
		}

		AVRational duration_base{.num = 1, .den = AV_TIME_BASE};
		(*callback)(av_rescale_q(duration, duration_base, inputCodecContext->time_base),
					av_rescale_q(duration, duration_base, inputCodecContext->time_base));

		if (writeOutputFileTrailer(outputFormatContext)) {
			throw std::runtime_error("ERROR_FAILED_TO_WRITE_TRAILER");
		}

		if (outputCodecContext) {
			avcodec_free_context(&outputCodecContext);
		}
		if (outputFormatContext) {
			avio_closep(&outputFormatContext->pb);
			avformat_free_context(outputFormatContext);
		}
		if (inputCodecContext) {
			avcodec_free_context(&inputCodecContext);
		}
		if (inputFormatContext) {
			avformat_close_input(&inputFormatContext);
		}
	} catch (std::exception &e) {
		printf("%s\n", e.what());

		if (outputCodecContext) {
			avcodec_free_context(&outputCodecContext);
		}
		if (outputFormatContext) {
			avio_closep(&outputFormatContext->pb);
			avformat_free_context(outputFormatContext);
		}
		if (inputCodecContext) {
			avcodec_free_context(&inputCodecContext);
		}
		if (inputFormatContext) {
			avformat_close_input(&inputFormatContext);
		}
		
		throw;
	}
}

void FFmpegManager::getFileInfo(const std::string& inputPath, AudioFileDescription& description)
{
	AVFormatContext *inputFormatContext = nullptr;
	AVCodecContext *inputCodecContext = nullptr;
	AVStream *audioStream = nullptr;

	try {
		if (openInputFile(inputPath, &inputFormatContext, &inputCodecContext)) {
			throw std::runtime_error("ERROR_UNSUPPORTED_FILE");
		}

		if (getAudioStream(inputFormatContext, &audioStream)) {
			throw std::runtime_error("ERROR_NOT_FOUND_AUDIO_STREAM");
		}

		const int64_t duration_seconds = inputFormatContext->duration / AV_TIME_BASE;
		const int64_t duration_mseconds = (inputFormatContext->duration - duration_seconds * AV_TIME_BASE) * 1000 / AV_TIME_BASE;

		description.codec = inputCodecContext->codec->long_name;
		description.profile = avcodec_profile_name(inputCodecContext->codec_id, inputCodecContext->profile);
		description.sampleRate = audioStream->codecpar->sample_rate;
		description.bitRate = audioStream->codecpar->bit_rate;
		description.channels = audioStream->codecpar->channels;
		description.duration.seconds = duration_seconds;
		description.duration.milliseconds = duration_mseconds;

		if (inputCodecContext) {
			avcodec_free_context(&inputCodecContext);
		}
		if (inputFormatContext) {
			avformat_close_input(&inputFormatContext);
		}
	} catch (std::exception &e) {
		printf("%s\n", e.what());

		if (inputCodecContext) {
			avcodec_free_context(&inputCodecContext);
		}
		if (inputFormatContext) {
			avformat_close_input(&inputFormatContext);
		}
		
		throw;
	}
}

FFmpegManager::FFmpegManager()
{
#if !FF_API_NEXT
	av_register_all();
#endif
}

FFmpegManager::~FFmpegManager()
{
}
