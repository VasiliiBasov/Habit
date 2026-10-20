import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_config.dart';
import '../auth/cubit/auth_cubit.dart';

/// Вкладка настроек: аккаунт, премиум-статус, выход.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user?.name ?? '—'),
                  subtitle: Text(user?.email ?? ''),
                  trailing: user?.premium == true
                      ? const Chip(
                          avatar: Icon(Icons.workspace_premium,
                              size: 18, color: Colors.amberAccent),
                          label: Text('Premium'),
                        )
                      : const Chip(label: Text('Free')),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: const Text('Premium-подписка'),
                      subtitle: const Text(
                          'Безлимитный ИИ-помощник, без рекламы.\n'
                          'Оплата через Google Play/App Store — на этапе релиза.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Подписка подключается через RevenueCat на следующем шаге'))),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.smart_toy_outlined),
                      title: Text('Лимит ИИ на Free'),
                      subtitle: Text(
                          '${AppConfig.freeDailyLimit} сообщений в день — обновляется ежедневно'),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.dns_outlined),
                      title: Text('Сервер'),
                      subtitle: Text(AppConfig.backendUrl),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthCubit>().logout(),
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Выйти',
                    style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('Habit App v0.1.0',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          );
        },
      ),
    );
  }
}
