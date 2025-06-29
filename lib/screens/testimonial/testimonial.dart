import 'package:flutter/material.dart';

class TestimonialsScreen extends StatelessWidget {
  const TestimonialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final testimonials = [
      {
        'name': 'Ana Clara',
        'avatar': 'https://i.imgur.com/BoN9kdC.png',
        'message':
            'O Hendril é uma pessoa incrível, sempre disposto a ajudar todo mundo! Merece todos os elogios ❤️',
      },
      {
        'name': 'Lucas Silva',
        'avatar': 'https://i.imgur.com/BoN9kdC.png',
        'message':
            'Parceiro demais! Sempre dá um jeito de resolver tudo com calma e inteligência.',
      },
      {
        'name': 'Maria Eduarda',
        'avatar': 'https://i.imgur.com/BoN9kdC.png',
        'message': 'Sem palavras pra esse cara. Um verdadeiro amigo! 💙',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Depoimentos')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          // abrir modal para novo depoimento
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: testimonials.length,
        itemBuilder: (context, index) {
          final t = testimonials[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(t['avatar']!),
                  radius: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t['message']!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
