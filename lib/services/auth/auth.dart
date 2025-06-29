import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:social/services/api/api.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final String _apiBaseUrl = ApiService.baseUrl;
  String? _verificationId;

  // Função para autenticação com Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        throw Exception("Sem conexão com a internet");
      }

      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn
          .signIn();
      if (googleSignInAccount == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult = await _auth.signInWithCredential(
        credential,
      );
      final User? user = authResult.user;

      if (user != null) {
        try {
          await _registerUserInBackend(
            uid: user.uid,
            name: user.displayName ?? 'Usuário Google',
            email: user.email ?? 'noemail@social.com',
            phone: user.phoneNumber ?? '',
            photoUrl: user.photoURL ?? '',
          );
        } catch (e) {
          if (kDebugMode) print('Registro no backend falhou: $e');
        }

        return authResult; // Retorna o UserCredential completo
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Erro na autenticação com Google: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  // Função para login com telefone
  Future<User?> signInWithPhone(String phoneNumber) async {
    try {
      // Verificar conectividade
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        throw Exception("Sem conexão com a internet");
      }

      // Enviar código de verificação
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception(e.message ?? "Falha na verificação");
        },
        codeSent: (String verificationId, int? resendToken) {
          // Você precisa implementar a lógica para inserir o código recebido via SMS
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (kDebugMode) print('Erro no login com telefone: $e');
      rethrow;
    }
    return null;
  }

  // Função para iniciar o processo de login com telefone
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(PhoneAuthCredential) onVerificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (kDebugMode) print('Erro na verificação de telefone: $e');
      rethrow;
    }
  }

  // Função para confirmar o código SMS
  Future<User?> confirmSMSCode(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw Exception('Nenhuma verificação de telefone em andamento');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _registerUserInBackend(
          uid: user.uid,
          name: user.displayName ?? 'Usuário',
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          photoUrl: user.photoURL ?? '',
        );
      }

      return user;
    } catch (e) {
      if (kDebugMode) print('Erro ao confirmar código SMS: $e');
      rethrow;
    }
  }

  // Registrar usuário no backend
  Future<void> _registerUserInBackend({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String photoUrl,
    String? username,
  }) async {
    try {
      final endpoint = '$_apiBaseUrl/auth/register';
      final response = await http.post(
        // Mudamos para POST
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'name': name,
          'email': email,
          'phone': phone,
          'photoUrl': photoUrl,
          'provider': email.isNotEmpty ? 'google' : 'phone',
          'profileCompleted': username != null,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        if (kDebugMode) {
          print('Erro no registro: ${response.statusCode} - ${response.body}');
        }
        // Não lança exceção para permitir que o login continue
      }
    } catch (e) {
      if (kDebugMode) print('Erro no registro backend: $e');
      // Não relançamos a exceção para permitir que o login continue
    }
  }

  // Obter token JWT do seu backend
  Future<String?> getAuthToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/token'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['token'];
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao obter token: $e');
    }
    return null;
  }

  // Função para logout do usuário
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      if (kDebugMode) print("Usuário desconectado com sucesso.");
    } catch (e) {
      if (kDebugMode) print("Erro ao desconectar usuário: $e");
    }
  }

  // Função para obter o usuário atualmente autenticado
  Future<User?> currentUser() async {
    return _auth.currentUser;
  }

  // Stream para monitorar alterações no estado de autenticação do usuário
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> updateUserProfile({
    required String displayName,
    required String username,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Atualiza no Firebase
        await user.updateDisplayName(displayName);

        // Atualiza no backend
        await _registerUserInBackend(
          uid: user.uid,
          name: displayName,
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          photoUrl: user.photoURL ?? '',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      // Validação básica no cliente
      if (username.length < 4 || username.length > 20) {
        return false;
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        return false;
      }

      final response = await http.get(
        Uri.parse(
          '$_apiBaseUrl/users/check-username?username=${Uri.encodeComponent(username)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['available'] ?? false;
      } else if (response.statusCode == 400) {
        // Erro de validação do servidor
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Nome de usuário inválido');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Erro ao verificar username: $e');
      rethrow;
    }
  }

  Future<void> completeUserProfile({
    required String displayName,
    required String username,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Atualiza no Firebase
        await user.updateDisplayName(displayName);

        // Atualiza no backend
        final response = await http.put(
          Uri.parse('$_apiBaseUrl/users/${user.uid}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'displayName': displayName,
            'username': username.toLowerCase(), // Normaliza para minúsculas
            'profileCompleted': true,
            'updatedAt': DateTime.now().toIso8601String(),
          }),
        );

        if (response.statusCode != 200) {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Falha ao atualizar perfil');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao completar perfil: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfileData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/users/${user.uid}'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao obter dados do usuário');
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar dados do usuário: $e');
      rethrow;
    }
  }
}
