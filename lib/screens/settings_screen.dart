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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.1),
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 40),
          children: [
            _buildGlassSection(
              title: 'Apparence',
              children: [
                SwitchListTile(
                  title: const Text('Mode Sombre', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Activer ou désactiver le thème sombre', style: TextStyle(fontSize: 12)),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  activeColor: accentColor,
                  onChanged: (value) => themeProvider.toggleTheme(value),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Couleur d\'accentuation', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildGlassSection(
              title: 'À propos',
              children: [
                _buildSimpleSettingItem('Version', '1.2.0'),
                _buildSimpleSettingItem('Développeur', 'DonChaminade'),
                _buildSimpleSettingItem('Expérience', 'DonZiker Premium'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
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
