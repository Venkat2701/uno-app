import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  User? _user;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _error;
  Timer? _inactivityTimer;
  DateTime? _lastActivity;
  static const int _inactivityTimeoutMinutes = 30;

  User? get user => _user;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    await _checkStoredSession();
  }

  Future<void> _checkStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityString = prefs.getString('last_activity');
    
    if (lastActivityString != null) {
      final lastActivity = DateTime.parse(lastActivityString);
      final now = DateTime.now();
      final difference = now.difference(lastActivity).inMinutes;
      
      if (difference >= _inactivityTimeoutMinutes) {
        await _clearStoredSession();
        await _auth.signOut();
      } else {
        _updateLastActivity();
        _startInactivityTimer();
      }
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    _isLoading = true;
    notifyListeners();

    if (user != null) {
      await _loadUserData(user.uid);
      _updateLastActivity();
      _startInactivityTimer();
    } else {
      _appUser = null;
      _stopInactivityTimer();
      await _clearStoredSession();
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
      _updateLastActivity();
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
    _stopInactivityTimer();
    await _clearStoredSession();
    await _auth.signOut();
  }

  void updateActivity() {
    _updateLastActivity();
    _resetInactivityTimer();
  }

  Future<void> _updateLastActivity() async {
    _lastActivity = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_activity', _lastActivity!.toIso8601String());
  }

  void _startInactivityTimer() {
    _stopInactivityTimer();
    _inactivityTimer = Timer(Duration(minutes: _inactivityTimeoutMinutes), () {
      logout();
    });
  }

  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _resetInactivityTimer() {
    if (_user != null) {
      _startInactivityTimer();
    }
  }

  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_activity');
  }

  @override
  void dispose() {
    _stopInactivityTimer();
    super.dispose();
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