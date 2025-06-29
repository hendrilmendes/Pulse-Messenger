import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:social/services/auth/auth.dart';

class ApiService {
  static const String baseUrl = 'https://social.hendrilmendes2015.workers.dev/api';
  static final client = http.Client();
  static const int timeoutSeconds = 30;

  // Headers comuns
  static Map<String, String> _defaultHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Método genérico para GET autenticado
  static Future<dynamic> authenticatedGet(String endpoint) async {
    try {
      final authService = AuthService();
      final token = await authService.getAuthToken();
      final response = await client
          .get(Uri.parse('$baseUrl/$endpoint'), headers: _defaultHeaders(token))
          .timeout(const Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  // Método genérico para POST
  static Future<dynamic> post(
    String endpoint,
    dynamic body, {
    bool auth = true,
  }) async {
    try {
      final token = auth ? await AuthService().getAuthToken() : null;
      final response = await client
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: _defaultHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  // Tratamento de respostas
  static dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        message: data['message'] ?? 'Erro na requisição',
        statusCode: response.statusCode,
        data: data,
      );
    }
  }

  // Tratamento de erros
  static void _handleError(dynamic e) {
    if (e is ApiException) throw e;
    if (e is http.ClientException) {
      throw ApiException(message: 'Erro de conexão: ${e.message}');
    }
    if (e is TimeoutException) {
      throw ApiException(message: 'Tempo de requisição excedido');
    }
    debugPrint('Erro na requisição: $e');
    throw ApiException(message: 'Erro desconhecido');
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (${statusCode ?? 'no status'})';
}
