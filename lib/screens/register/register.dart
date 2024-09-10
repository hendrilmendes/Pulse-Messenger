// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social/providers/auth_provider.dart';
import 'package:social/screens/login/login.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar"),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Criar uma Conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

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
                      prefixIcon:
                          const Icon(Icons.email, color: Colors.black54),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 30),

                  // Botão de registro
       ElevatedButton(
  onPressed: () async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      // Verifica se o email já está registrado
      final isRegistered = await Provider.of<AuthProvider>(context, listen: false)
          .isEmailRegistered(email);

      if (isRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email já registrado.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Impede a criação de um novo usuário se o email já estiver em uso
      }

      // Se o email não estiver registrado, prossegue com o registro
      final result = await Provider.of<AuthProvider>(context, listen: false)
          .signUpWithEmail(email, password, context);

      // Verifica se o usuário foi criado com sucesso
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro bem-sucedido! Faça login.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navega para a tela de login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
    } catch (e) {
      // Caso haja um erro inesperado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esse email já esta cadastrado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: const Text(
    'Criar',
    style: TextStyle(
      fontSize: 18,
    ),
  ),
)
       ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
