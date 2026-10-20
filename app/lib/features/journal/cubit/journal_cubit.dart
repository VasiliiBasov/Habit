import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../data/journal_api.dart';

class JournalState extends Equatable {
  final bool loading;
  final List<JournalEntryModel> entries;
  final String? error;

  const JournalState({
    this.loading = false,
    this.entries = const [],
    this.error,
  });

  @override
  List<Object?> get props => [loading, entries, error];
}

class JournalCubit extends Cubit<JournalState> {
  final JournalApi _api;
  final int habitId;

  JournalCubit(this._api, this.habitId) : super(const JournalState());

  Future<void> load() async {
    emit(JournalState(loading: true, entries: state.entries));
    try {
      final entries = await _api.list(habitId);
      emit(JournalState(entries: entries));
    } catch (e) {
      emit(JournalState(
          entries: state.entries, error: asApiException(e).message));
    }
  }

  Future<bool> add(String title, String? text, int mood) async {
    try {
      await _api.create(habitId, title, text, mood);
      await load();
      return true;
    } catch (e) {
      emit(JournalState(
          entries: state.entries, error: asApiException(e).message));
      return false;
    }
  }
}
