import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../data/habit_models.dart';
import '../data/habits_api.dart';

class HabitDetailState extends Equatable {
  final bool loading;
  final StatsModel? stats;

  /// Момент получения stats — для живого пересчёта счётчика в UI.
  final DateTime? fetchedAt;
  final String? error;

  const HabitDetailState({
    this.loading = false,
    this.stats,
    this.fetchedAt,
    this.error,
  });

  @override
  List<Object?> get props => [loading, stats, fetchedAt, error];
}

/// Статистика конкретной привычки + действие «сорвался».
class HabitDetailCubit extends Cubit<HabitDetailState> {
  final HabitsApi _api;
  final int habitId;

  HabitDetailCubit(this._api, this.habitId)
      : super(const HabitDetailState());

  Future<void> load() async {
    emit(HabitDetailState(loading: true, stats: state.stats, fetchedAt: state.fetchedAt));
    try {
      final stats = await _api.stats(habitId);
      emit(HabitDetailState(stats: stats, fetchedAt: DateTime.now()));
    } catch (e) {
      emit(HabitDetailState(
          stats: state.stats,
          fetchedAt: state.fetchedAt,
          error: asApiException(e).message));
    }
  }

  Future<bool> relapse({String? note}) async {
    try {
      await _api.relapse(habitId, note: note);
      await load();
      return true;
    } catch (e) {
      emit(HabitDetailState(
          stats: state.stats,
          fetchedAt: state.fetchedAt,
          error: asApiException(e).message));
      return false;
    }
  }
}
