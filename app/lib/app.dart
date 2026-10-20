import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/storage/token_storage.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/register_screen.dart';
import 'features/chat/data/chat_api.dart';
import 'features/chat/ui/chat_screen.dart';
import 'features/habits/cubit/habit_detail_cubit.dart';
import 'features/habits/cubit/habits_cubit.dart';
import 'features/habits/data/habit_models.dart';
import 'features/habits/data/habits_api.dart';
import 'features/habits/ui/habit_detail_screen.dart';
import 'features/habits/ui/habits_list_screen.dart';
import 'features/home/home_shell.dart';
import 'features/journal/data/journal_api.dart';
import 'features/settings/settings_screen.dart';

/// Пересоздаёт redirect-логику go_router при смене AuthState.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class HabitApp extends StatefulWidget {
  final TokenStorage tokenStorage;
  final AuthCubit authCubit;
  final AuthApi authApi;
  final HabitsApi habitsApi;
  final JournalApi journalApi;
  final ChatApi chatApi;

  const HabitApp({
    super.key,
    required this.tokenStorage,
    required this.authCubit,
    required this.authApi,
    required this.habitsApi,
    required this.journalApi,
    required this.chatApi,
  });

  @override
  State<HabitApp> createState() => _HabitAppState();
}

class _HabitAppState extends State<HabitApp> {
  late final GoRouter _router;
  late final GoRouterRefreshStream _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = GoRouterRefreshStream(widget.authCubit.stream);
    _router = GoRouter(
      initialLocation: '/habits',
      refreshListenable: _refresh,
      redirect: (context, state) {
        final status = widget.authCubit.state.status;
        final onAuthScreens = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        if (status == AuthStatus.unauthenticated && !onAuthScreens) {
          return '/login';
        }
        if (status == AuthStatus.authenticated && onAuthScreens) {
          return '/habits';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => HomeShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/habits',
                  builder: (_, _) => const HabitsListScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/chat', builder: (_, _) => const ChatScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/settings',
                  builder: (_, _) => const SettingsScreen()),
            ]),
          ],
        ),
        GoRoute(
          path: '/habits/:id',
          builder: (context, state) {
            final habit = state.extra as HabitModel;
            return BlocProvider(
              create: (ctx) =>
                  HabitDetailCubit(ctx.read<HabitsApi>(), habit.id)..load(),
              child: HabitDetailScreen(habit: habit),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _refresh.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.tokenStorage),
        RepositoryProvider.value(value: widget.authApi),
        RepositoryProvider.value(value: widget.habitsApi),
        RepositoryProvider.value(value: widget.journalApi),
        RepositoryProvider.value(value: widget.chatApi),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: widget.authCubit),
          // BlocListener ниже срабатывает только на смену статуса, поэтому
          // при восстановленной сессии (restore() в main()) грузим список сразу.
          BlocProvider(create: (ctx) {
            final habits = HabitsCubit(ctx.read<HabitsApi>());
            if (ctx.read<AuthCubit>().state.status == AuthStatus.authenticated) {
              habits.load();
            }
            return habits;
          }),
        ],
        // После логина/логаута чистим или наполняем список привычек
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (a, b) => a.status != b.status,
          listener: (context, state) {
            final habits = context.read<HabitsCubit>();
            if (state.status == AuthStatus.authenticated) {
              habits.load();
            } else if (state.status == AuthStatus.unauthenticated) {
              habits.clear();
            }
          },
          child: MaterialApp.router(
            title: 'Свобода от привычек',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
            ),
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}

