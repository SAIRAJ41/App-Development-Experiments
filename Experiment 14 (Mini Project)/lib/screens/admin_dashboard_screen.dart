import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lunaris/services/auth_service.dart';
import 'package:lunaris/services/database_service.dart';
import 'package:lunaris/theme_provider.dart';
import 'package:provider/provider.dart';
import '../shared_widgets.dart'; // We will use GlassContainer and NeonText again

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  String? get _currentUserId => _dbService.currentUserId;

  void _togglePremium(String userId, bool currentStatus) {
    if (userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Admins cannot change their own status here."),
        backgroundColor: Colors.red,
      ));
      return;
    }
    _dbService.setPremiumStatus(userId, !currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final authService = AuthService(); // For logging out
    
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
            
    final colors = isDarkMode
        ? (
            accent1: LunarisColorsDark.accentCyan,
            accent2: LunarisColorsDark.accentMagenta,
            text: LunarisColorsDark.text
          )
        : (
            accent1: LunarisColorsLight.accentViolet,
            accent2: LunarisColorsLight.accentMagenta,
            text: LunarisColorsLight.text
          );

    return Scaffold(
      // --- 1. REVERTED TO USE AppBackground ---
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AppBackground(isLightMode: !isDarkMode),
          // --- END REVERT ---
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                iconTheme: IconThemeData(color: colors.text),
                // --- 2. REVERTED TO NeonText ---
                title: NeonText(
                  text: 'Admin Dashboard',
                  gradientColors: [colors.accent1, colors.accent2],
                  fontSize: 22,
                ),
                // --- END REVERT ---
                actions: [
                  IconButton(
                    icon: Icon(Icons.logout, color: colors.text),
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    },
                  )
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  // --- 3. REVERTED TO NeonText ---
                  child: NeonText(
                    text: 'User Management',
                    gradientColors: [colors.accent1, colors.accent2],
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                  // --- END REVERT ---
                ),
              ),
              _buildUserList(colors),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100), // Padding for nav bar
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(dynamic colors) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _dbService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(
                "Error: ${snapshot.error}. Check Firestore Rules.",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(
                "No users found.",
                style: TextStyle(color: colors.text),
              ),
            ),
          );
        }

        final users = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data();
              final String userId = userDoc.id;

              final String name = userData['displayName'] ?? 'No Name';
              final bool isPremium = userData['isPremium'] ?? false;
              final bool isAdmin = userData['isAdmin'] ?? false;
              final String email = userData['email'] ?? 'No Email';

              // --- 4. REVERTED TO GlassContainer AND ListTile ---
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: GlassContainer(
                  child: ListTile(
                    title: Text(
                      name,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: TextStyle(
                        color: colors.text.withOpacity(0.7),
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- 5. THIS IS THE UI FIX ---
                        // Dynamic Text: Shows "ADMIN", "Premium", or "Standard"
                        Text(
                          isAdmin ? 'ADMIN' 
                                  : (isPremium ? 'Premium' : 'Standard'),
                          style: TextStyle(
                            color: isAdmin ? colors.accent2 
                                   : (isPremium ? colors.accent1 
                                   : colors.text.withOpacity(0.7)),
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        
                        // Only show the switch if the user is NOT an admin
                        if (!isAdmin)
                          Switch(
                            value: isPremium,
                            onChanged: (newValue) {
                              // Admin cannot change their own status
                              if (userId == _currentUserId) return;
                              _togglePremium(userId, isPremium);
                            },
                            activeColor: colors.accent1,
                            // Disable switch for admin's own record
                            inactiveThumbColor: (userId == _currentUserId)
                                ? Colors.grey.withOpacity(0.5)
                                : null,
                            activeTrackColor: (userId == _currentUserId)
                                ? Colors.grey.withOpacity(0.5)
                                : colors.accent1.withOpacity(0.5),
                          ),
                      ],
                    ),
                    // --- END OF FIX ---
                  ),
                ),
              );
              // --- END REVERT ---
            },
            childCount: users.length,
          ),
        );
      },
    );
  }
}