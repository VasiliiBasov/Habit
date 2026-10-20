import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/chat_api.dart';

/// Отображаемое сообщение (включая генерируемое прямо сейчас).
class UiMessage extends Equatable {
  final bool fromUser;
  final String text;
  final bool isError;

  /// true, пока ассистент ещё стримит ответ.
  final bool streaming;

  const UiMessage({
    required this.fromUser,
    required this.text,
    this.isError = false,
    this.streaming = false,
  });

  UiMessage copyWith({String? text, bool? streaming, bool? isError}) =>
      UiMessage(
        fromUser: fromUser,
        text: text ?? this.text,
        streaming: streaming ?? this.streaming,
        isError: isError ?? this.isError,
      );

  @override
  List<Object?> get props => [fromUser, text, isError, streaming];
}

class ChatState extends Equatable {
  final int? habitId;
  final List<UiMessage> messages;
  final bool sending;
  final int? limitRemaining;

  const ChatState({
    this.habitId,
    this.messages = const [],
    this.sending = false,
    this.limitRemaining,
  });

  ChatState copyWith({
    int? habitId,
    List<UiMessage>? messages,
    bool? sending,
    int? limitRemaining,
  }) =>
      ChatState(
        habitId: habitId ?? this.habitId,
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        limitRemaining: limitRemaining ?? this.limitRemaining,
      );

  @override
  List<Object?> get props => [habitId, messages, sending, limitRemaining];
}

class ChatCubit extends Cubit<ChatState> {
  final ChatApi _api;

  ChatCubit(this._api) : super(const ChatState());

  /// Переключение контекста на другую привычку + подгрузка истории.
  Future<void> selectHabit(int habitId) async {
    if (state.habitId == habitId) return;
    emit(ChatState(habitId: habitId, limitRemaining: state.limitRemaining));
    try {
      final history = await _api.history();
      emit(state.copyWith(
        messages: history
            .map((m) => UiMessage(fromUser: m.role == 'USER', text: m.content))
            .toList(),
      ));
    } catch (_) {
      // историю можно не показывать, чат всё равно работает
    }
  }

  Future<void> refreshLimit() async {
    final limit = await _api.limit();
    if (limit != null) {
      emit(state.copyWith(limitRemaining: limit.remaining));
    }
  }

  Future<void> send(String text) async {
    final habitId = state.habitId;
    final trimmed = text.trim();
    if (habitId == null || trimmed.isEmpty || state.sending) return;

    final base = [
      ...state.messages,
      UiMessage(fromUser: true, text: trimmed),
      const UiMessage(fromUser: false, text: '', streaming: true),
    ];
    emit(state.copyWith(messages: base, sending: true));

    var acc = '';
    try {
      await for (final chunk in _api.send(habitId: habitId, message: trimmed)) {
        acc = chunk.isError ? chunk.text : acc + chunk.text;
        final updated = [...state.messages];
        updated[updated.length - 1] = updated.last.copyWith(
          text: chunk.isError ? chunk.text : acc,
          isError: chunk.isError,
          streaming: !chunk.isError,
        );
        emit(state.copyWith(messages: updated));
        if (chunk.isError) break;
      }
    } catch (_) {
      // asApiException обёртка уже произошла в api; показываем в пузыре
      final updated = [...state.messages];
      updated[updated.length - 1] = updated.last.copyWith(
        text: 'Соединение потерялось. Попробуйте ещё раз.',
        isError: true,
        streaming: false,
      );
      emit(state.copyWith(messages: updated));
    } finally {
      final updated = [...state.messages];
      if (updated.isNotEmpty) {
        updated[updated.length - 1] =
            updated.last.copyWith(streaming: false);
        emit(state.copyWith(messages: updated, sending: false));
      } else {
        emit(state.copyWith(sending: false));
      }
      await refreshLimit();
    }
  }

}
