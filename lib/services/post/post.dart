import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:social/models/post_model.dart';

class PostService {
  static const String _baseUrl = 'https://social.hendrilmendes2015.workers.dev/api/posts';

  Future<List<PostModel>> fetchPosts() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar postagens');
    }
  }
}
