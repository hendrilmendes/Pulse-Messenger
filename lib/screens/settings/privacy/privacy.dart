import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidade'),
      ),
      body: const Center(
        child: Text('Tela de Privacidade'),
      ),
    );
  }
}
