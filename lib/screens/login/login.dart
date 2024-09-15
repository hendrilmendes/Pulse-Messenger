// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social/providers/auth_provider.dart';
import 'package:social/screens/create_profile/create_profile.dart';
import 'package:social/screens/home/home.dart';
import 'package:social/screens/register/register.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Card(
                elevation: 15,
                shape: CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 150,
                  child: Image(
                    image: AssetImage('assets/img/logo.png'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bem vindo!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Campo de email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.black54),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),

              // Campo de senha
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.black54),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Botão de login com email e senha
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      final email = _emailController.text;
                      final password = _passwordController.text;

                      try {
                        await authProvider.signInWithEmail(email, password);

                        if (authProvider.isAuthenticated) {
                          final user = authProvider.currentUser;

                          if (user != null) {
                            final hasProfile =
                                await authProvider.hasCompleteProfile(user);

                            if (hasProfile) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) => const HomeScreen()),
                                (Route<dynamic> route) =>
                                    false, // Remove todas as rotas anteriores
                              );
                            } else {
                              Navigator.pushReplacement(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      CreateProfileScreen(user: user),
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Falha ao fazer login. Verifique suas credenciais.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Botão de login com Google
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await authProvider.signInWithGoogle();

                        if (authProvider.isAuthenticated) {
                          final user = authProvider.currentUser;

                          if (user != null) {
                            final hasProfile =
                                await authProvider.hasCompleteProfile(user);

                            if (hasProfile) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) => const HomeScreen()),
                                (Route<dynamic> route) =>
                                    false, // Remove todas as rotas anteriores
                              );
                            } else {
                              Navigator.pushReplacement(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      CreateProfileScreen(user: user),
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Falha ao fazer login com Google.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Login com Google'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Link para registro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: const Text('Não tem uma conta? Crie uma agora'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
