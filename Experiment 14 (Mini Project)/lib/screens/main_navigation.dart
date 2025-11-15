import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lunaris/navigation_provider.dart';
import 'package:lunaris/theme_provider.dart';
import 'package:lunaris/shared_widgets.dart';
import 'package:lunaris/services/database_service.dart';

// --- Corrected Imports ---
// Using relative paths as this file is inside the 'screens' directory
import 'home_page.dart';
import 'search_page.dart';
import 'watchlist_page.dart';
import 'profile_page.dart';
import 'admin_dashboard_screen.dart';
// --- End of Imports ---

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  bool _hasShownAd = false; // Track if ad has been shown in this session

  @override
  void initState() {
    super.initState();
    // Show promotional ad on app start/login (once per session)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait a bit for UI to be ready
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && !_hasShownAd) {
        _hasShownAd = true;
        await showPremiumPromotionAd(
          context,
          title: 'Welcome to Lunaris!',
          message: 'Upgrade to Premium for an ad-free experience and unlock exclusive features!',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final navProvider = Provider.of<NavigationProvider>(context);
    final dbService = DatabaseService();

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

    // --- StreamBuilder for Admin Status ---
    return StreamBuilder<bool>(
      stream: dbService.isUserAdmin(),
      initialData: false,
      builder: (context, adminSnapshot) {
        final bool isAdmin = adminSnapshot.data ?? false;

        // --- Dynamically create pages and icons ---
        final List<Widget> pages = [
          const HomeScreen(),
          const SearchScreen(),
          const WatchlistScreen(),
          const ProfileScreen(),
          if (isAdmin) const AdminDashboardScreen(), // Add admin page if admin
        ];

        final List<IconData> icons = [
          Icons.home_filled,
          Icons.search,
          Icons.movie_filter_sharp,
          Icons.person,
          if (isAdmin) Icons.admin_panel_settings, // Add admin icon if admin
        ];

        // --- THIS IS THE FIX ---
        // We need a variable to hold the index we will *display* on this frame.
        int displayIndex = navProvider.selectedIndex;
        
        // Check if the current selected index is out of bounds
        if (navProvider.selectedIndex >= pages.length) {
          // Schedule the *actual* state change to happen *after* this build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navProvider.setIndex(0); // Reset to home
          });
          // For *this* build frame, just show the home page to avoid the crash.
          displayIndex = 0;
        }
        // --- END OF FIX ---

        // --- StreamBuilder for Premium Status (for FAB) ---
        return StreamBuilder<bool>(
          stream: dbService.isUserPremium(),
          initialData: false,
          builder: (context, premiumSnapshot) {
            final bool isPremium = premiumSnapshot.data ?? false;
            
            // --- Admin also gets premium perks ---
            final bool hasPremiumAccess = isPremium || isAdmin;

            return Scaffold(
              extendBody: true,
              backgroundColor: Colors.transparent,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              floatingActionButton: GlassmorphicFAB(
                pulseColor: colors.accent2,
                onTap: () {
                  // --- UPDATED: Use hasPremiumAccess ---
                  if (hasPremiumAccess) { 
                    Navigator.pushNamed(context, '/ai_bot');
                  } else {
                    Navigator.pushNamed(context, '/premium_lounge');
                  }
                },
              ),
              bottomNavigationBar: GlassmorphicNavBar(
                // --- USE THE SAFE 'displayIndex' ---
                selectedIndex: displayIndex,
                onTap: (index) {
                  navProvider.setIndex(index);
                },
                icons: icons, // Use the dynamic list
                activeColor: colors.accent1,
                inactiveColor: colors.text.withOpacity(0.5),
              ),
              body: Stack(
                children: [
                  AppBackground(
                    isLightMode: !isDarkMode,
                  ),
                  IndexedStack(
                    // --- USE THE SAFE 'displayIndex' ---
                    index: displayIndex,
                    children: pages, // Use the dynamic list
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}