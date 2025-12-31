import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  User? _user;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    _isLoading = true;
    notifyListeners();

    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _appUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final snapshot = await _database.child('users').child(uid).get();
      if (snapshot.exists) {
        _appUser = AppUser.fromJson(uid, snapshot.value as Map<dynamic, dynamic>);
      } else {
        _appUser = null;
      }
    } catch (e) {
      _error = e.toString();
      _appUser = null;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String username) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createUserDocument(credential.user!.uid, email, username);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _createUserDocument(String uid, String email, String username) async {
    final userData = AppUser(uid: uid, email: email, username: username);
    await _database.child('users').child(uid).set(userData.toJson());
    // Load the user data immediately after creating it
    await _loadUserData(uid);
  }

  Future<void> refreshUserData() async {
    if (_user != null) {
      await _loadUserData(_user!.uid);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication failed';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}