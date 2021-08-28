// Project imports:
import 'package:spoon_cast_converter/models/redux/app-state.dart';

export 'package:spoon_cast_converter/models/redux/action/version-check-action.dart';

class AddInputFilePathListAction {
  final String filepath;

  const AddInputFilePathListAction({required this.filepath});
}

class RemoveInputFilePathListAction {
  final int index;

  const RemoveInputFilePathListAction({required this.index});
}

class UpdateOutputFilePathAction {
  final int index;
  final String? outputFilePath;

  const UpdateOutputFilePathAction({
    required this.index,
    this.outputFilePath,
  });
}

class SelectInputFilePathListAction {
  final int index;

  const SelectInputFilePathListAction({required this.index});
}

class OpenInputFileAction {
  final String filePath;

  const OpenInputFileAction({required this.filePath});
}

class ConvertFileAction {
  final String inputFilePath;
  final String outputFilePath;

  const ConvertFileAction({
    required this.inputFilePath,
    required this.outputFilePath,
  });
}

class UpdateFileInfoAction {
  final AudioFileInfo? fileInfo;

  const UpdateFileInfoAction({this.fileInfo});
}

class UpdateConvertingIndexAction {
  final int convertingIndex;

  const UpdateConvertingIndexAction({
    required this.convertingIndex,
  });
}

class UpdateConvertingStatusAction {
  final Rational convertingStatus;

  const UpdateConvertingStatusAction({
    required this.convertingStatus,
  });
}

class StartConvertSequenceAction {
  const StartConvertSequenceAction();
}

class ContinueNextConvertSequenceAction {
  const ContinueNextConvertSequenceAction();
}

class RequestConvertAction {
  final bool forceConvert;

  const RequestConvertAction({
    this.forceConvert = false,
  });
}

class UpdateModalInfoAction {
  final ModalInfo modalInfo;

  const UpdateModalInfoAction({
    required this.modalInfo,
  });
}

class CheckAndAddInputFilePathListAction {
  final String filepath;

  const CheckAndAddInputFilePathListAction({
    required this.filepath,
  });
}
