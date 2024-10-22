import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  String? get email {
    return _auth.currentUser!.email;
  }

  Stream<User?> get user {
    return _auth.authStateChanges(); // Listen to auth state changes
  }

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();
      return userCredential.user;
    } catch (error) {
      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'weak-password':
            throw ('Password must have at least 6 characters with lowercase, uppercase, special characters.');
          case 'too-many-requests':
            throw ('Please try again in a while.');
          default:
            throw ('An error occured during registration.');
        }
      } else {
        throw ('An unknown error occurred.');
      }
    }
  }

  Future<UserCredential?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } catch (error) {
      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'user-not-found':
            throw ('User not found.');
          case 'wrong-password':
            throw ('User not found.');
          case 'invalid-email':
            throw ('User not found.');
          default:
            throw ('An unknown error occurred.');
        }
      } else {
        throw ('An unknown error occurred.');
      }
    }
  }

  Future<void> sendResetPasswordEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (error) {}
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool isUserLogged() {
    var currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.emailVerified) {
      return true;
    }
    return false;
  }

  Future<String?> getCurrentUserIdToken() async {
    var user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    } else {
      return null;
    }
  }
}
