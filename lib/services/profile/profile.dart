import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:social/models/profile_model.dart';
import 'package:social/services/auth/auth.dart';

class ProfileService {
  static const String _baseUrl = 'https://social.hendrilmendes2015.workers.dev/api';
  final AuthService _auth = AuthService();

  Future<UserProfile> getProfile() async {
    final token = await _auth.getAuthToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return UserProfile.fromJson(data); // classe com as propriedades: uid, name, avatar, email...
    } else {
      throw Exception('Falha ao carregar perfil: ${res.statusCode}');
    }
  }
}
