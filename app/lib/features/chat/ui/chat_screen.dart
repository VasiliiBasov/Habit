import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../habits/cubit/habits_cubit.dart';
import '../cubit/chat_cubit.dart';
import 'widgets/chat_bubble.dart';

/// Вкладка ИИ-помощника: чат со стримингом ответа по SSE.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChatCubit(ctx.read())..refreshLimit(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _showPaywallStub(BuildContext context, String reason) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Premium'),
        content: Text('$reason\n\n'
            'Безлимитный ИИ-помощник и расширенная статистика — в подписке. '
            'Оплата (Google Play/App Store) подключится на следующем этапе.'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Понятно')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitsCubit>().state.habits;
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        _scrollDown();
        final last = state.messages.isEmpty ? null : state.messages.last;
        if (last != null &&
            last.isError &&
            !last.fromUser &&
            !state.sending &&
            last.text.toLowerCase().contains('лимит')) {
          _showPaywallStub(context, last.text);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('ИИ-помощник'),
            actions: [
              if (state.limitRemaining != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Text('Осталось: ${state.limitRemaining}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: habits.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                              'Чтобы общаться с помощником, сначала добавьте '
                              'привычку на вкладке «Мои привычки».'),
                        ),
                      )
                    : DropdownMenu<int>(
                        expandedInsets: EdgeInsets.zero,
                        initialSelection: state.habitId,
                        label: const Text('Контекст разговора'),
                        dropdownMenuEntries: [
                          for (final h in habits)
                            DropdownMenuEntry(value: h.id, label: h.name),
                        ],
                        onSelected: (id) {
                          if (id != null) {
                            context.read<ChatCubit>().selectHabit(id);
                          }
                        },
                      ),
              ),
              Expanded(
                child: state.habitId == null
                    ? const Center(
                        child: Text('Выберите привычку — помощник учтёт её '
                            'в контексте разговора'))
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) =>
                            ChatBubble(message: state.messages[i]),
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          enabled: state.habitId != null && !state.sending,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Например: тянет сорваться…',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: state.habitId == null || state.sending
                            ? null
                            : _send,
                        icon: state.sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _send() {
    context.read<ChatCubit>().send(_input.text);
    _input.clear();
  }
}

