import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social/models/status_model.dart';
import 'package:social/screens/status/view/view.dart';
import 'package:social/screens/status/create/create.dart';
import 'package:social/services/status/status.dart';
import 'package:social/widgets/avatar.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  late Future<List<Status>> _recentFuture;
  late Future<List<Status>> _viewedFuture;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchStatuses();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Adiciona listener para mudanças no usuário
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  void _fetchStatuses() {
    final service = StatusService();
    _recentFuture = service.getRecentStatuses();
    _viewedFuture = service.getViewedStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Momentos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchStatuses();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _myStatusCard(context),
            const SizedBox(height: 16),
            const Text(
              'Atualizações recentes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Status>>(
              future: _recentFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snap.hasError) {
                  return Center(child: Text('Erro: ${snap.error}'));
                } else if (snap.hasData) {
                  final recent = snap.data!;
                  if (recent.isEmpty) {
                    // Mensagem quando não há status recentes
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum status recente',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Column(
                    children: recent
                        .map((s) => _statusTile(context, s))
                        .toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Status>>(
              future: _viewedFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snap.hasError) {
                  return Center(child: Text('Erro: ${snap.error}'));
                } else if (snap.hasData) {
                  final viewed = snap.data!;
                  return Visibility(
                    visible: viewed.isNotEmpty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Visualizados',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...viewed.map((s) => _statusTile(context, s)).toList(),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _myStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.grey, width: 1.0),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CreateStatusScreen()),
              );
              if (created == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Momento publicado com sucesso!'),
                  ),
                );
                _fetchStatuses();
                setState(() {});
              }
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserAvatar(
                  radius: 30,
                  photoUrl: _currentUser?.photoURL,
                  displayName: _currentUser?.displayName,
                ),
                const CircleAvatar(
                  radius: 10,
                  child: Icon(CupertinoIcons.add, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Meus Momentos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Toque para adicionar seu status',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusTile(BuildContext context, Status status) {
    return ListTile(
      leading: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: status.viewed ? Colors.grey : Colors.green,
          ),
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(status.userPhotoUrl),
          ),
        ],
      ),
      title: Text(status.userName),
      subtitle: Text(_formatTime(status.createdAt)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewStatusScreen(
              name: status.userName,
              imageUrl: status.imageUrl ?? '',
              time: _formatTime(status.createdAt),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutos atrás';
    if (diff.inHours < 24) return '${diff.inHours} horas atrás';
    return '${diff.inDays} dias atrás';
  }
}
