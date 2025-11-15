import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lunaris/navigation_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// --- Screen Imports ---
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/main_navigation.dart';
import 'screens/settings_page.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/intro_screen.dart';
import 'services/ai_bot.dart'; // <-- 2. IMPORT ADDED
import 'shared_widgets.dart'; // Import for Movie class

import 'theme_provider.dart'; // Import the new ThemeNotifier

// AuthGate remains the same
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs)),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const LunarisApp(),
    ),
  );
}

class LunarisApp extends StatelessWidget {
  const LunarisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Lunaris',
      debugShowCheckedModeBanner: false,
      theme: lunarisLightTheme,
      darkTheme: lunarisDarkTheme,
      themeMode: themeNotifier.themeMode,
      home: const IntroScreen(child: AuthGate()),

      // Routes are still needed for direct navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/settings': (context) => const SettingsScreen(),
        // --- 3. ROUTES UPDATED/ADDED ---
        '/premium_lounge': (context) => const PremiumLoungeScreen(),
        '/ai_bot': (context) => const AiBotScreen(),
      },

      // --- NEW: Handle the movie detail route ---
      onGenerateRoute: (settings) {
        if (settings.name == '/details') {
          // Extract the Movie object from the arguments
          final movie = settings.arguments as Movie;
          return MaterialPageRoute(
            builder: (context) {
              return MovieDetailScreen(movie: movie);
            },
          );
        }
        return null; // Let routes handle it
      },
    );
  }
}