import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';

// ─── Auth Repository Provider ─────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

// ─── Auth State - holds current user or null ─────────────────────────────────
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authResponse = await _repo.login(email, password);
      state = AsyncValue.data(authResponse.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? className,
    String? section,
    String? rollNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authResponse = await _repo.register(
        name: name,
        email: email,
        password: password,
        role: role,
        className: className,
        section: section,
        rollNumber: rollNumber,
      );
      state = AsyncValue.data(authResponse.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _repo.changePassword(oldPassword, newPassword);
    } catch (e, st) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshUser() async {
    final user = await _repo.getCurrentUser();
    state = AsyncValue.data(user);
  }
}
