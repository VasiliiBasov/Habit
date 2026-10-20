import 'package:flutter/material.dart';

import '../../cubit/chat_cubit.dart';

/// Пузырь сообщения. Пока ассистент стримит и текста ещё нет — спиннер.
class ChatBubble extends StatelessWidget {
  final UiMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align =
        message.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isError
        ? Colors.red.withValues(alpha: 0.15)
        : message.fromUser
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest;
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: message.streaming && message.text.isEmpty
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(message.text),
        ),
      ],
    );
  }
}
