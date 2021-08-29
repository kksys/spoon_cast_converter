// Package imports:
import 'package:redux/redux.dart';
import 'package:uuid/uuid.dart';

// Project imports:
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

final filepathReducer = combineReducers<AppState>([
  new TypedReducer<AppState, AddConvertItemAction>(_addConvertItemReducer),
  new TypedReducer<AppState, RemoveConvertItemAction>(_removeConvertItemReducer),
  new TypedReducer<AppState, UpdateConvertItemAction>(_updateConvertItemReducer),
  new TypedReducer<AppState, SelectConvertFileListAction>(_selectConvertFileListReducer),
  new TypedReducer<AppState, UpdateFileInfoAction>(_updateFileInfoReducer),
  new TypedReducer<AppState, UpdateConvertingIndexAction>(_updateConvertingIndexReducer),
  new TypedReducer<AppState, UpdateConvertingStatusAction>(_updateConvertingStatusReducer),
  new TypedReducer<AppState, UpdateModalInfoAction>(_updateModalInfo),
]);

AppState _addConvertItemReducer(
  AppState state,
  AddConvertItemAction action,
) {
  final uuid = Uuid();
  String? newId = action.convertItem.id;
  AppState newState = state;

  if (newId == null) {
    final idList = state.convertFileList.map((e) => e.id);

    do {
      newId = uuid.v4();
    } while (idList.contains(newId));

    newState = AppState.fromMap({
      ...state.toMap(),
      'convertFileList': [
        ...state.convertFileList,
        ConvertItem(
          id: newId,
          inputFilePath: action.convertItem.inputFilePath,
          outputFilePath: action.convertItem.outputFilePath,
        ),
      ].map((e) => e.toMap()).toList(),
    });
  }

  return newState;
}

AppState _removeConvertItemReducer(
  AppState state,
  RemoveConvertItemAction action,
) {
  int selectedIndex = state.selectedIndex;
  List<ConvertItem> convertFileList = [...state.convertFileList];
  AudioFileInfo? fileInfo = state.fileInfo;

  if (convertFileList.map((e) => e.id).contains(action.id)) {
    convertFileList = convertFileList.where((e) => e.id != action.id).toList();
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

AppState _updateConvertItemReducer(
  AppState state,
  UpdateConvertItemAction action,
) {
  List<ConvertItem> convertFileList = [...state.convertFileList];

  if (convertFileList.map((e) => e.id).contains(action.convertItem.id) &&
      action.convertItem.id != null) {
    final index = convertFileList.indexWhere((e) => e.id == action.convertItem.id);
    convertFileList[index] = action.convertItem;
  }

  return AppState.fromMap({
    ...state.toMap(),
    'convertFileList': convertFileList.map((e) => e.toMap()).toList(),
  });
}

AppState _selectConvertFileListReducer(
  AppState state,
  SelectConvertFileListAction action,
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
