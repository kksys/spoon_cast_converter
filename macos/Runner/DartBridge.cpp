//
//  DartBridge.cpp
//  Runner
//
//  Created by KK Systems on 2021/08/02.
//

#include <stdio.h>
#include "FFmpegManager.hpp"
#include <exception>

extern "C" __attribute__((visibility("default"))) __attribute__((used))
const char* getFileInfo(const char* filePath)
{
	AudioFileDescription description = {"", 0};
	static std::string result = "";

	try {
		FFmpegManager::getInstance().getFileInfo(filePath, description);

		result  = "{";
		result += "\"status\":\"SUCCESS\",";
		result += "\"response\":{";
		result += "\"codec\":\"" + std::string(description.codec) + "\",";
		if (description.profile) {
			result += "\"profile\":\"" + std::string(description.profile) + "\",";
		}
		result += "\"sample_rates\":" + std::to_string(description.sampleRate) + ",";
		result += "\"bit_rates\":" + std::to_string(description.bitRate) + ",";
		result += "\"channels\":" + std::to_string(description.channels) + ",";
		result += "\"duration\":{";
		result += "\"seconds\":" + std::to_string(description.duration.seconds) + ",";
		result += "\"milliseconds\":" + std::to_string(description.duration.milliseconds);
		result += "}";
		result += "}";
		result += "}";
	} catch (std::exception &e) {
		result  = "{";
		result += "\"status\":\"FAILED\",";
		result += "\"error\":\"" + std::string(e.what()) + "\"";
		result += "}";
	}

	return result.c_str();
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
const char* convertFile(const char* inputFilePath, const char* outputFilePath, const ConvertingCallback callback)
{
	static std::string result = "";
	
	try {
		FFmpegManager::getInstance().convertFile(inputFilePath, outputFilePath, callback);

		result  = "{";
		result += "\"status\":\"SUCCESS\",";
		result += "\"response\":{";
		result += "}";
		result += "}";
	} catch (std::exception &e) {
		result  = "{";
		result += "\"status\":\"FAILED\",";
		result += "\"error\":\"" + std::string(e.what()) + "\"";
		result += "}";
	}
	
	return result.c_str();
}
