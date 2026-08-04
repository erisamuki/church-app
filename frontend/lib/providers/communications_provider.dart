import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/communication.dart';
import 'auth_provider.dart';

class CommunicationsProvider extends ChangeNotifier {
  final AuthProvider authProvider;

  CommunicationsProvider({required this.authProvider});

  List<Communication> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Communication> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 1. Fetch all communications
  Future<void> fetchCommunications() async {
    if (authProvider.token == null) {
      _error = 'Unauthorized: No token found.';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final response = await http
          .get(
            Uri.parse('${authProvider.baseUrl}/communications'),
            headers: authProvider.authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> commsData = data['data'] ?? data;
        _messages = commsData.map((json) => Communication.fromJson(json)).toList();
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to load communications.';
      }
    } catch (e) {
      _error = 'Network error while fetching communications.';
    } finally {
      _setLoading(false);
    }
  }

  // 2. Send or create a new communication message
  Future<bool> sendCommunication({
    required String subject,
    required String message,
    required String type, // e.g., 'email', 'sms', 'announcement'
  }) async {
    if (authProvider.token == null) return false;

    _setLoading(true);
    _error = null;

    try {
      final response = await http
          .post(
            Uri.parse('${authProvider.baseUrl}/communications'),
            headers: authProvider.authHeaders,
            body: jsonEncode({
              'subject': subject,
              'message': message,
              'type': type,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchCommunications(); // Refresh the list after sending
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to send communication.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error while sending communication.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
