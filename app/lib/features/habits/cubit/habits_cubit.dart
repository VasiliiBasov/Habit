import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../data/habit_models.dart';
import '../data/habits_api.dart';

class HabitsState extends Equatable {
  final bool loading;
  final List<HabitModel> habits;
  final String? error;

  const HabitsState({
    this.loading = false,
    this.habits = const [],
    this.error,
  });

  @override
  List<Object?> get props => [loading, habits, error];
}

/// Список привычек (верхнеуровневый, живёт всю сессию).
class HabitsCubit extends Cubit<HabitsState> {
  final HabitsApi _api;

  HabitsCubit(this._api) : super(const HabitsState());

  Future<void> load() async {
    emit(HabitsState(loading: true, habits: state.habits));
    try {
      final habits = await _api.list();
      emit(HabitsState(habits: habits));
    } catch (e) {
      emit(HabitsState(habits: state.habits, error: asApiException(e).message));
    }
  }

  Future<bool> create(String name, double costPerDay, String currency) async {
    try {
      await _api.create(name, costPerDay, currency);
      await load();
      return true;
    } catch (e) {
      emit(HabitsState(habits: state.habits, error: asApiException(e).message));
      return false;
    }
  }

  Future<bool> archive(int id) async {
    try {
      await _api.archive(id);
      await load();
      return true;
    } catch (e) {
      emit(HabitsState(habits: state.habits, error: asApiException(e).message));
      return false;
    }
  }

  void clear() => emit(const HabitsState());
}
