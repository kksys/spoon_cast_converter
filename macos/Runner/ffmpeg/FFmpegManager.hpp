//
//  FFmpegManager.hpp
//  Runner
//
//  Created by KK Systems on 2021/08/01.
//

#ifndef FFmpegManager_hpp
#define FFmpegManager_hpp

#include <stdio.h>
#include <string>

typedef struct _Duration {
	int64_t		seconds;
	int64_t		milliseconds;
} Duration;

typedef struct _AudioFileDescription {
	const char*	codec;
	const char*	profile;
	int			sampleRate;
	int64_t		bitRate;
	int			channels;
	Duration	duration;
} AudioFileDescription;

typedef void (*ConvertingCallback)(int64_t current, int64_t duration);

class FFmpegManager
{
public:
	static FFmpegManager& getInstance(void);

	void convertFile(const std::string& inputPath, const std::string& outputPath, const ConvertingCallback callback);
	void getFileInfo(const std::string& inputPath, AudioFileDescription& description);

private:
	FFmpegManager(void);
	~FFmpegManager(void);
};

#endif /* FFmpegManager_hpp */
