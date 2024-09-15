import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.privacy,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // Seção: Quem pode ver meus dados
          _buildSectionTitle('Quem pode ver meus dados'),
          _buildPrivacyOption(
            icon: Icons.visibility,
            option: 'Última vez vista',
            value: 'Todos',
          ),
          _buildPrivacyOption(
            icon: Icons.person,
            option: 'Foto do perfil',
            value: 'Meus contatos',
          ),
          _buildPrivacyOption(
            icon: Icons.info,
            option: 'Sobre',
            value: 'Meus contatos',
          ),
          _buildPrivacyOption(
            icon: Icons.insert_comment,
            option: 'Status',
            value: 'Meus contatos',
          ),
          const SizedBox(height: 16),

          // Seção: Segurança
          _buildSectionTitle('Segurança'),
          _buildPrivacyOption(
            icon: Icons.check_box,
            option: 'Exibir notificações de leitura',
            value: 'Ativado',
          ),
          _buildPrivacyOption(
            icon: Icons.message,
            option: 'Exibir notificações de digitação',
            value: 'Ativado',
          ),
          const SizedBox(height: 16),

          // Seção: Contas bloqueadas
          _buildSectionTitle('Contas bloqueadas'),
          _buildBlockedContactsList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required IconData icon,
    required String option,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(option,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Handle option tap
      },
    );
  }

  Widget _buildBlockedContactsList() {
    // Lista de contatos bloqueados (substituir pelos dados reais)
    final blockedContacts = ['Contato 1', 'Contato 2', 'Contato 3'];

    return Column(
      children: blockedContacts.map((contact) {
        return ListTile(
          leading: const Icon(Icons.person, color: Colors.red),
          title: Text(contact),
          trailing: const Icon(Icons.delete, color: Colors.red),
          onTap: () {
            // Handle unblock contact
          },
        );
      }).toList(),
    );
  }
}
