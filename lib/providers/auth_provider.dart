import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        if (kDebugMode) {
          print('Login bem-sucedido para o usuário: ${result.user?.email}');
        }
      } else {
        if (kDebugMode) {
          print('Falha ao obter o usuário após o login.');
        }
      }

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Erro ao autenticar: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro inesperado: $e');
      }
    }
  }

  Future<User?> signUpWithEmail(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Não redireciona para CreateProfileScreen aqui
        return result.user; // Retorna o usuário registrado
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Erro ao criar usuário: ${e.message}');
      }
      rethrow; // Lança a exceção para tratamento
    } catch (e) {
      if (kDebugMode) {
        print('Erro inesperado: $e');
      }
      rethrow; // Lança a exceção para tratamento
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners(); // Notifica os ouvintes de que o estado mudou
    if (kDebugMode) {
      print('Usuário deslogado com sucesso');
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      // ignore: deprecated_member_use
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Erro ao verificar email: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Erro inesperado: $e');
      }
      return false;
    }
  }

  // Verifica se o usuário tem um perfil completo
  Future<bool> hasCompleteProfile(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists &&
          doc.data() != null; // Verifica se o documento existe e não é nulo
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao verificar perfil: $e');
      }
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final result = await _auth.signInWithCredential(credential);

        if (result.user != null) {
          if (kDebugMode) {
            print(
              'Login com Google bem-sucedido para o usuário: ${result.user?.email}',
            );
          }
        } else {
          if (kDebugMode) {
            print('Falha ao obter o usuário após o login com Google.');
          }
        }
      }
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Erro ao autenticar com Google: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro inesperado ao autenticar com Google: $e');
      }
    }
  }

  Future<void> resetPassword(String email) async {
    // Lógica para enviar e-mail de redefinição de senha
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(
        'Erro ao enviar e-mail de redefinição de senha: ${e.toString()}',
      );
    }
  }
}
