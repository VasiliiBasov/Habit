import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../data/auth_models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final bool busy;

  /// Одноразовое сообщение об ошибке (показываем через SnackBar).
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.busy = false,
    this.error,
  });

  @override
  List<Object?> get props => [status, user, busy, error];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthApi _api;
  final TokenStorage _storage;

  AuthCubit(this._api, this._storage) : super(const AuthState());

  /// Восстановление сессии при запуске: токен в хранилище → проверка /me.
  Future<void> restore() async {
    final token = await _storage.read();
    if (token == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }
    try {
      final user = await _api.me();
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      await _storage.clear();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthState(status: state.status, user: state.user, busy: true));
    try {
      final result = await _api.login(email.trim(), password);
      await _storage.save(result.token);
      emit(AuthState(status: AuthStatus.authenticated, user: result.user));
    } catch (e) {
      emit(AuthState(
        status: state.status,
        user: state.user,
        error: asApiException(e).message,
      ));
    }
  }

  Future<void> register(String email, String password, String name) async {
    emit(AuthState(status: state.status, user: state.user, busy: true));
    try {
      final result = await _api.register(email.trim(), password, name.trim());
      await _storage.save(result.token);
      emit(AuthState(status: AuthStatus.authenticated, user: result.user));
    } catch (e) {
      emit(AuthState(
        status: state.status,
        user: state.user,
        error: asApiException(e).message,
      ));
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
