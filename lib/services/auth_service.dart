import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para gestionar la autenticación de usuarios con Firebase Auth
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Emite los cambios de sesión en tiempo real (usuario autenticado o null)
  Stream<User?> get usuarioActual => _firebaseAuth.authStateChanges();

  /// Usuario autenticado actualmente (o null si no hay sesión)
  User? get usuario => _firebaseAuth.currentUser;

  /// Inicia sesión con email y contraseña.
  ///
  /// Retorna el [User] autenticado o lanza una [Exception] con un
  /// mensaje entendible en español si ocurre un error.
  Future<User> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('No se pudo iniciar sesión. Intenta nuevamente.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mensajeError(e));
    } catch (_) {
      throw Exception(
        'Ocurrió un error inesperado al iniciar sesión. Intenta nuevamente.',
      );
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> cerrarSesion() async {
    await _firebaseAuth.signOut();
  }

  /// Traduce los códigos de error de Firebase Auth a mensajes en español
  String _mensajeError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'Correo o contraseña incorrectos';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'network-request-failed':
        return 'Problema de conexión. Verifica tu internet e intenta de nuevo';
      default:
        return 'No se pudo iniciar sesión. Intenta nuevamente';
    }
  }
}
