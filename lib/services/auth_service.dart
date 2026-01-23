import 'package:trip_bud/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract class AuthService {
  Future<User?> login(String email, String password);
  Future<User?> register(String email, String password, String displayName);
  Future<User?> loginWithGoogle();
  Future<void> logout();
  Future<bool> resetPassword(String email);
  User? getCurrentUser();
  bool isLoggedIn();
}

class MockAuthService extends AuthService {
  User? _currentUser;

  @override
  Future<User?> login(String email, String password) async {
    // Mock login - in production, use Firebase
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = User(
      id: 'mock_${email.hashCode}',
      email: email,
      displayName: email.split('@')[0],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _currentUser;
  }

  @override
  Future<User?> register(
    String email,
    String password,
    String displayName,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = User(
      id: 'mock_${email.hashCode}',
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _currentUser;
  }

  @override
  Future<User?> loginWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = User(
      id: 'mock_google_user',
      email: 'user@google.com',
      displayName: 'Google User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<bool> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  @override
  User? getCurrentUser() => _currentUser;

  @override
  bool isLoggedIn() => _currentUser != null;
}

class FirebaseAuthService extends AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseAuthService();

  User? _userFromFirebase(fb_auth.User? fbUser) {
    if (fbUser == null) return null;
    final now = DateTime.now();
    return User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName ?? fbUser.email?.split('@').first ?? '',
      photoUrl: fbUser.photoURL,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _userFromFirebase(cred.user);
  }

  @override
  Future<User?> register(
    String email,
    String password,
    String displayName,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = cred.user;
    if (fbUser != null) {
      await fbUser.updateDisplayName(displayName);
      await fbUser.reload();
    }
    return _userFromFirebase(_auth.currentUser);
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  @override
  Future<bool> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
    return true;
  }

  @override
  User? getCurrentUser() => _userFromFirebase(_auth.currentUser);

  @override
  bool isLoggedIn() => _auth.currentUser != null;

  @override
  Future<User?> loginWithGoogle() async {
    return signInWithGoogle();
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web, use the Firebase popup flow which avoids needing the
        // separate GoogleSignIn JS flow/config.
        final provider = fb_auth.GoogleAuthProvider();
        final userCred = await _auth.signInWithPopup(provider);
        return _userFromFirebase(userCred.user);
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      return _userFromFirebase(userCred.user);
    } catch (e) {
      // Bubble up a clear exception for UI to display
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }
}
