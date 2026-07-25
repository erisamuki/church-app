import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// User model matching your PostgreSQL schema
class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? department;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.department,
    this.avatarUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      role: json['role'] ?? 'member',
      phone: json['phone'],
      department: json['department'],
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role,
    'phone': phone,
    'department': department,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}

class AuthProvider extends ChangeNotifier {
  final String baseUrl; // e.g., 'http://localhost:3000/api'

  AuthProvider({required this.baseUrl});

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  /// Initialize auth state from local storage on app start
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('bcc_auth_token');
    final userJson = prefs.getString('bcc_user_data');

    if (_token != null && userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson));
        notifyListeners();
      } catch (e) {
        await logout();
      }
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        _token = data['token'];
        _user = User.fromJson(data['user']);

        // Persist to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bcc_auth_token', _token!);
        await prefs.setString('bcc_user_data', jsonEncode(_user!.toJson()));

        _setLoading(false);
        return true;
      } else {
        _error = data['message'] ?? data['error'] ?? 'Login failed. Please try again.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Network error. Check your connection.';
      _setLoading(false);
      return false;
    }
  }

  /// Logout and clear all stored data
  Future<void> logout() async {
    _token = null;
    _user = null;
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bcc_auth_token');
    await prefs.remove('bcc_user_data');

    notifyListeners();
  }

  /// Get auth headers for API requests
  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Fetch current user profile (useful for refreshing data)
  Future<bool> fetchCurrentUser() async {
    if (_token == null) return false;

    try {
      final response = await http.get(Uri.parse('$baseUrl/auth/me'), headers: authHeaders);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user'] ?? data);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

