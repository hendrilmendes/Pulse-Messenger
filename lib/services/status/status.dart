import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:social/models/status_model.dart';
import 'package:social/services/auth/auth.dart';

class StatusService {
  static const String _baseUrl =
      'https://social.hendrilmendes2015.workers.dev/api';
  final AuthService _authService = AuthService();

  Future<List<Status>> getRecentStatuses() async {
    try {
      final token = await _authService.getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/status/recent'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Status.fromJson(json)).toList();
      }
      throw Exception('Failed to load recent statuses');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Status>> getViewedStatuses() async {
    try {
      final token = await _authService.getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/status/viewed'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Status.fromJson(json)).toList();
      }
      throw Exception('Failed to load viewed statuses');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markStatusAsViewed(String statusId) async {
    try {
      final token = await _authService.getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/status/$statusId/view'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark status as viewed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> publishStatus({String? caption, String? imageUrl}) async {
    final token = await _authService.getAuthToken();
    final res = await http.post(
      Uri.parse('$_baseUrl/status/publish'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'caption': caption, 'imageUrl': imageUrl}),
    );
    if (res.statusCode == 201) {
      final body = jsonDecode(res.body);
      return body['id'].toString();
    } else {
      throw Exception('Falha ao publicar status: ${res.body}');
    }
  }
}
