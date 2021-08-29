// Project imports:
import 'package:spoon_cast_converter/models/redux/app-state.dart';

export 'package:spoon_cast_converter/models/redux/action/version-check-action.dart';

class AddConvertItemAction {
  final ConvertItem convertItem;

  const AddConvertItemAction({required this.convertItem});
}

class RemoveConvertItemAction {
  final String id;

  const RemoveConvertItemAction({required this.id});
}

class UpdateConvertItemAction {
  final ConvertItem convertItem;

  const UpdateConvertItemAction({
    required this.convertItem,
  });
}

class SelectConvertFileListAction {
  final int index;

  const SelectConvertFileListAction({required this.index});
}

class GetFileInfoAction {
  final String filePath;

  const GetFileInfoAction({required this.filePath});
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
  final ConvertItem convertItem;

  const CheckAndAddInputFilePathListAction({
    required this.convertItem,
  });
}
