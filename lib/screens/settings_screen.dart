import 'package:flutter/material.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _lowStockAlerts = true;
  String _apiEndpoint = 'http://localhost:5000/api';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModatexColors.background,
      appBar: AppBar(
        title: const Text('Réglages'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ModatexColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ModatexColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Administrateur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ModatexColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'admin@modatex.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: ModatexColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Fonctionnalité à venir'),
                        backgroundColor: ModatexColors.primary,
                      ),
                    );
                  },
                  child: const Text('Modifier le profil'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Notifications Section
          _buildSectionTitle('Notifications'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: ModatexColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Activer les notifications',
                  subtitle: 'Recevoir les notifications de l\'app',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                Divider(height: 1, color: ModatexColors.divider),
                _buildSwitchTile(
                  icon: Icons.warning_amber_outlined,
                  title: 'Alertes stock bas',
                  subtitle: 'Être notifié quand le stock est faible',
                  value: _lowStockAlerts,
                  onChanged: (value) {
                    setState(() => _lowStockAlerts = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // API Configuration Section
          _buildSectionTitle('Configuration API'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ModatexColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Point d\'accès API',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ModatexColors.accent,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: _apiEndpoint),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.cloud_outlined, color: ModatexColors.accent),
                    hintText: 'http://localhost:5000/api',
                  ),
                  onChanged: (value) {
                    setState(() => _apiEndpoint = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'État de connexion',
                      style: TextStyle(
                        fontSize: 12,
                        color: ModatexColors.accent,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: ModatexColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: ModatexColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Connecté',
                            style: TextStyle(
                              fontSize: 11,
                              color: ModatexColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Storage Section
          _buildSectionTitle('Stockage'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: ModatexColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.cached_outlined,
                  title: 'Vider le cache',
                  subtitle: 'Libérer de l\'espace',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: ModatexColors.surface,
                        title: const Text(
                          'Vider le cache',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        content: const Text('Voulez-vous vraiment vider le cache ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Annuler',
                              style: TextStyle(color: ModatexColors.accent),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Cache vidé avec succès'),
                                  backgroundColor: ModatexColors.success,
                                ),
                              );
                            },
                            child: const Text('Confirmer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: ModatexColors.divider),
                _buildListTile(
                  icon: Icons.download_outlined,
                  title: 'Exporter les données',
                  subtitle: 'Télécharger en CSV',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Fonctionnalité à venir'),
                        backgroundColor: ModatexColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionTitle('À propos'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: ModatexColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.info_outline,
                  title: 'Version de l\'app',
                  subtitle: '1.0.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Modatex',
                      applicationVersion: '1.0.0',
                      applicationIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ModatexColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'M',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      children: const [
                        Text('Une solution complète de gestion de stock pour votre entreprise.'),
                      ],
                    );
                  },
                ),
                Divider(height: 1, color: ModatexColors.divider),
                _buildListTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Politique de confidentialité',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Fonctionnalité à venir'),
                        backgroundColor: ModatexColors.primary,
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: ModatexColors.divider),
                _buildListTile(
                  icon: Icons.description_outlined,
                  title: 'Conditions d\'utilisation',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Fonctionnalité à venir'),
                        backgroundColor: ModatexColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Danger Zone
          _buildSectionTitle('Zone de danger', isError: true),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: ModatexColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ModatexColors.error.withOpacity(0.2)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.logout, color: ModatexColors.error),
              title: Text(
                'Déconnexion',
                style: TextStyle(
                  color: ModatexColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: ModatexColors.error),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: ModatexColors.surface,
                    title: const Text(
                      'Déconnexion',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Annuler',
                          style: TextStyle(color: ModatexColors.accent),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Déconnecté avec succès'),
                              backgroundColor: ModatexColors.success,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ModatexColors.error,
                        ),
                        child: const Text('Déconnecter'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isError = false}) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isError ? ModatexColors.error : ModatexColors.accent,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ModatexColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: ModatexColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: ModatexColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: ModatexColors.accent,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: ModatexColors.primary,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ModatexColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: ModatexColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: ModatexColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: ModatexColors.accent,
              ),
            )
          : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: ModatexColors.accent),
      onTap: onTap,
    );
  }
}
