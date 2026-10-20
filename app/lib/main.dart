import 'package:flutter/material.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/data/auth_api.dart';
import 'features/chat/data/chat_api.dart';
import 'features/habits/data/habits_api.dart';
import 'features/journal/data/journal_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Собираем граф зависимостей вручную — просто и прозрачно
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final authApi = AuthApi(apiClient);
  final authCubit = AuthCubit(authApi, tokenStorage);

  // Восстанавливаем сессию до первого кадра, чтобы роутер сразу
  // отправил на нужный экран без «мигания» логина
  await authCubit.restore();

  runApp(HabitApp(
    tokenStorage: tokenStorage,
    authCubit: authCubit,
    authApi: authApi,
    habitsApi: HabitsApi(apiClient),
    journalApi: JournalApi(apiClient),
    chatApi: ChatApi(apiClient),
  ));
}
