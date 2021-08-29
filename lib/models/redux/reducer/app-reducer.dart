// Package imports:
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/models/redux/app-state.dart';
import 'package:spoon_cast_converter/models/redux/reducer/filepath-reducer.dart';

AppState appReducer(AppState state, action) {
  return combineReducers<AppState>([
    filepathReducer,
  ])(state, action);
}
