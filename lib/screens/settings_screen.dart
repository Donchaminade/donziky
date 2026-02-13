import 'package:donziker/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionTitle(context, 'Apparence'),
          SwitchListTile(
            title: const Text('Mode Sombre'),
            subtitle: const Text('Activer ou désactiver le thème sombre'),
            value: themeProvider.themeMode == ThemeMode.dark,
            activeColor: accentColor,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          _buildSectionTitle(context, 'Couleur d\'accentuation'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildColorOption(themeProvider, Colors.redAccent),
                _buildColorOption(themeProvider, Colors.blueAccent),
                _buildColorOption(themeProvider, Colors.greenAccent),
                _buildColorOption(themeProvider, Colors.purpleAccent),
                _buildColorOption(themeProvider, Colors.orangeAccent),
                _buildColorOption(themeProvider, Colors.pinkAccent),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'À propos'),
          _buildSimpleSettingItem('Version', '1.0.0'),
          _buildSimpleSettingItem('Développeur', 'DonChaminade'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorOption(ThemeProvider provider, Color color) {
    final isSelected = provider.accentColor == color;
    return GestureDetector(
      onTap: () => provider.updateAccentColor(color),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSettingItem(String title, String trailing) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        trailing,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildToggleSettingItem(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(description),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.redAccent,
    );
  }

  Widget _buildDescriptionSettingItem(String title, String description) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      onTap: () {
        // Handle item tap
      },
    );
  }
}
