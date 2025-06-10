import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    _token = prefs.getString('token');
    // Potentially fetch user data here if token exists, or assume valid until first API call fails
    // For simplicity, we'll assume if token is present, user is "logged in"
    // A robust app would verify the token with the backend and fetch user details
    if (_token != null) {
      // Placeholder: In a real app, you'd fetch user details using the token
      _user = User(username: prefs.getString('username') ?? 'User');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.registerUser(
        username,
        email,
        password,
      );
      if (response['success']) {
        // Optionally login directly after registration or prompt user to login
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error']?.toString() ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.loginUser(username, password);
      if (response['success'] && response['token'] != null) {
        _token = response['token'];
        // In a real app, the login response should also include user details
        // or you make another call to fetch user details.
        _user = User(username: username); // Placeholder
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString(
          'username',
          username,
        ); // Storing username for auto-login placeholder
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error']?.toString() ?? 'Login failed';
        if (response['statusCode'] != null) {
          _errorMessage = '$_errorMessage (Status: ${response['statusCode']})';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _apiService.logoutUser(); // Clears SharedPreferences
    _user = null;
    _token = null;
    _isLoading = false;
    final prefs =
        await SharedPreferences.getInstance(); // Also clear local username
    await prefs.remove('username');
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
