import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:social/models/chat_model.dart';
import 'package:social/services/auth/auth.dart';

class ChatService {
  static const _baseUrl = 'https://social.hendrilmendes2015.workers.dev/api';
  final AuthService _auth = AuthService();

  Future<List<Conversation>> getConversations() async {
    final token = await _auth.getAuthToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/chat/conversations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Conversation.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao carregar conversas: ${res.statusCode}');
    }
  }
}
