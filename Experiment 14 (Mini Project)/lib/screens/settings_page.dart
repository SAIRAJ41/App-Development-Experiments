import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening links
import '../services/auth_service.dart';
import '../theme_provider.dart';
import '../shared_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true; // Default value

  // Function to launch the help URL
  Future<void> _launchHelpUrl() async {
    final Uri url = Uri.parse('https://sites.google.com/view/lunarishelp/home');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open help website.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    final colors = isDarkMode
        ? (
            accent1: LunarisColorsDark.accentCyan,
            accent2: LunarisColorsDark.accentMagenta,
            text: LunarisColorsDark.text,
          )
        : (
            accent1: LunarisColorsLight.accentViolet,
            accent2: LunarisColorsLight.accentMagenta,
            text: LunarisColorsLight.text,
          );

    return Scaffold(
      body: Stack(
        children: [
          // --- UPDATED: Use AppBackground ---
          AppBackground(
            isLightMode: !isDarkMode,
          ),
          // Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent, // Handled by blur
                elevation: 0,
                centerTitle: false,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter( 
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), 
                    child: Container(color: Colors.transparent),
                  ),
                ),
                title: NeonText(
                  text: 'Settings & Preferences',
                  gradientColors: [colors.accent1, colors.accent2],
                  fontSize: 22,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GlassContainer(
                        child: Column(
                          children: [
                            _buildNotificationToggle(colors),
                            const CustomDivider(),
                            _buildNavTile(
                              context: context,
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              onTap: _launchHelpUrl,
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32.0),
                      // Log Out Button (moved from Profile)
                      GradientButton(
                        text: "LOG OUT",
                        gradient: LinearGradient(
                          colors: [colors.accent2, colors.accent1],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        onPressed: () async {
                          await _authService.signOut();
                          if (mounted) {
                            // Navigate to login and clear navigation stack
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget for the Notification Toggle
  Widget _buildNotificationToggle(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_none, color: colors.accent1),
              const SizedBox(width: 16),
              Text(
                'Notifications',
                style: TextStyle(
                  color: colors.text,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
                // TODO: Save notification preference
              });
            },
            activeColor: colors.accent1,
            inactiveThumbColor: colors.text.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  // Helper widget (copied from profile page)
  Widget _buildNavTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return ListTile(
      leading: Icon(icon, color: colors.accent1),
      title: Text(
        title,
        style: TextStyle(
          color: colors.text,
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          color: colors.text.withOpacity(0.5), size: 16),
      onTap: onTap,
    );
  }
}