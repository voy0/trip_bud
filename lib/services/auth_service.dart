import 'package:trip_bud/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
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
  Future<void> updateUserLanguage(String userId, String languageCode);
  Future<String?> getUserLanguage(String userId);
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

  @override
  Future<void> updateUserLanguage(String userId, String languageCode) async {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        displayName: _currentUser!.displayName,
        photoUrl: _currentUser!.photoUrl,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
        languageCode: languageCode,
      );
    }
  }

  @override
  Future<String?> getUserLanguage(String userId) async {
    return _currentUser?.languageCode ?? 'en';
  }
}

class FirebaseAuthService extends AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  User? _cachedUser;

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
      languageCode: 'en',
    );
  }

  @override
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = cred.user;
    if (fbUser != null) {
      // Fetch user data from Firestore to get language preference
      final userDoc = await _firestore
          .collection('users')
          .doc(fbUser.uid)
          .get();
      final languageCode = userDoc.data()?['languageCode'] ?? 'en';

      _cachedUser = User(
        id: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName ?? fbUser.email?.split('@').first ?? '',
        photoUrl: fbUser.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        languageCode: languageCode,
      );
      return _cachedUser;
    }
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

      // Create user document in Firestore with default language
      await _firestore.collection('users').doc(fbUser.uid).set({
        'email': email,
        'displayName': displayName,
        'languageCode': 'en',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, firestore.SetOptions(merge: true));

      _cachedUser = User(
        id: fbUser.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        languageCode: 'en',
      );
      return _cachedUser;
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
  User? getCurrentUser() => _cachedUser ?? _userFromFirebase(_auth.currentUser);

  @override
  bool isLoggedIn() => _auth.currentUser != null;

  @override
  Future<void> updateUserLanguage(String userId, String languageCode) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'languageCode': languageCode,
        'updatedAt': DateTime.now().toIso8601String(),
      }, firestore.SetOptions(merge: true));

      // Update cached user
      if (_cachedUser != null) {
        _cachedUser = User(
          id: _cachedUser!.id,
          email: _cachedUser!.email,
          displayName: _cachedUser!.displayName,
          photoUrl: _cachedUser!.photoUrl,
          createdAt: _cachedUser!.createdAt,
          updatedAt: DateTime.now(),
          languageCode: languageCode,
        );
      }
    } catch (e) {
      throw Exception('Failed to update user language: ${e.toString()}');
    }
  }

  @override
  Future<String?> getUserLanguage(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['languageCode'] ?? 'en';
    } catch (_) {
      return 'en';
    }
  }

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
