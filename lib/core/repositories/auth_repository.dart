class AuthResult {
  final bool success;
  final bool isOffline;
  final bool isPending;
  final String? token;
  final String? username;
  final String? errorMessage;

  const AuthResult({
    required this.success,
    this.isOffline = false,
    this.isPending = false,
    this.token,
    this.username,
    this.errorMessage,
  });

  factory AuthResult.online({String? token, String? username}) => AuthResult(
        success: true,
        token: token,
        username: username,
      );

  factory AuthResult.offline({String? username}) => AuthResult(
        success: true,
        isOffline: true,
        username: username,
      );

  factory AuthResult.pending({String? username}) => AuthResult(
        success: true,
        isPending: true,
        username: username,
      );

  factory AuthResult.failure(String message) => AuthResult(
        success: false,
        errorMessage: message,
      );
}

abstract class AuthRepository {
  Future<AuthResult> login({required String email, required String password});

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<bool> isAuthenticated();
}
