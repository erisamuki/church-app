import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/sermon.dart';
import 'auth_provider.dart';

class SermonsProvider extends ChangeNotifier {
  final AuthProvider authProvider;

  SermonsProvider({required this.authProvider});

  List<Sermon> _sermons = [];
  bool _isLoading = false;
  String? _error;

  List<Sermon> get sermons => _sermons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 1. Fetch Sermons
  Future<void> fetchSermons() async {
    if (authProvider.token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('${authProvider.baseUrl}/sermons'),
            headers: authProvider.authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> sermonsData = data['data'] ?? data;
        _sermons = sermonsData.map((json) => Sermon.fromJson(json)).toList();
      } else {
        _error = 'Failed to load sermons.';
      }
    } catch (e) {
      _error = 'Network error while fetching sermons.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Add New Sermon (POST request)
  Future<bool> addSermon({
    required String title,
    required String speaker,
    String? series,
    required DateTime date,
    String? audioUrl,
    String? videoUrl,
  }) async {
    if (authProvider.token == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('${authProvider.baseUrl}/sermons'),
            headers: authProvider.authHeaders,
            body: jsonEncode({
              'title': title,
              'speaker': speaker,
              'series': series,
              'date': date.toIso8601String(),
              'audio_url': audioUrl,
              'video_url': videoUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSermons(); // Refresh list after adding
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to create sermon.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error while creating sermon.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
