// Package imports:
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

final filepathReducer = combineReducers<AppState>([
  new TypedReducer<AppState, AddInputFilePathListAction>(_addInputFilePathListReducer),
  new TypedReducer<AppState, RemoveInputFilePathListAction>(_removeInputFilePathListReducer),
  new TypedReducer<AppState, UpdateOutputFilePathAction>(_updateOutputFilePathReducer),
  new TypedReducer<AppState, SelectInputFilePathListAction>(_selectInputFilePathListReducer),
  new TypedReducer<AppState, UpdateFileInfoAction>(_updateFileInfoReducer),
  new TypedReducer<AppState, UpdateConvertingIndexAction>(_updateConvertingIndexReducer),
  new TypedReducer<AppState, UpdateConvertingStatusAction>(_updateConvertingStatusReducer),
  new TypedReducer<AppState, UpdateModalInfoAction>(_updateModalInfo),
]);

AppState _addInputFilePathListReducer(
  AppState state,
  AddInputFilePathListAction action,
) {
  List<ConvertItem> convertFileList = [
    ...state.convertFileList,
    ConvertItem(inputFilePath: action.filepath)
  ];
  return AppState.fromMap({
    ...state.toMap(),
    'convertFileList': convertFileList.map((e) => e.toMap()).toList(),
  });
}

AppState _removeInputFilePathListReducer(
  AppState state,
  RemoveInputFilePathListAction action,
) {
  int selectedIndex = state.selectedIndex;
  List<ConvertItem> convertFileList = [...state.convertFileList];
  AudioFileInfo? fileInfo = state.fileInfo;

  if (convertFileList.asMap().containsKey(action.index)) {
    convertFileList.removeAt(action.index);
    selectedIndex = -1;
    fileInfo = null;
  }

  return AppState.fromMap({
    ...state.toMap(),
    'selectedIndex': selectedIndex,
    'convertFileList': convertFileList.map((e) => e.toMap()).toList(),
    'fileInfo': fileInfo?.toMap()
  });
}

AppState _updateOutputFilePathReducer(
  AppState state,
  UpdateOutputFilePathAction action,
) {
  List<ConvertItem> convertFileList = [...state.convertFileList];

  if (convertFileList.asMap().containsKey(action.index)) {
    final ConvertItem previousItem = convertFileList[action.index];
    convertFileList[action.index] = ConvertItem(
      inputFilePath: previousItem.inputFilePath,
      outputFilePath: action.outputFilePath,
    );
  }

  return AppState.fromMap({
    ...state.toMap(),
    'convertFileList': convertFileList.map((e) => e.toMap()).toList(),
  });
}

AppState _selectInputFilePathListReducer(
  AppState state,
  SelectInputFilePathListAction action,
) {
  return AppState.fromMap({
    ...state.toMap(),
    'selectedIndex': action.index,
  });
}

AppState _updateFileInfoReducer(
  AppState state,
  UpdateFileInfoAction action,
) {
  return AppState.fromMap({
    ...state.toMap(),
    'fileInfo': action.fileInfo?.toMap(),
  });
}

AppState _updateConvertingIndexReducer(
  AppState state,
  UpdateConvertingIndexAction action,
) {
  return AppState.fromMap({
    ...state.toMap(),
    'convertingIndex': action.convertingIndex,
  });
}

AppState _updateConvertingStatusReducer(
  AppState state,
  UpdateConvertingStatusAction action,
) {
  return AppState.fromMap({
    ...state.toMap(),
    'convertingStatus': action.convertingStatus.toMap(),
  });
}

AppState _updateModalInfo(
  AppState state,
  UpdateModalInfoAction action,
) {
  return AppState.fromMap({
    ...state.toMap(),
    'modalInfo': action.modalInfo.toMap(),
  });
}
