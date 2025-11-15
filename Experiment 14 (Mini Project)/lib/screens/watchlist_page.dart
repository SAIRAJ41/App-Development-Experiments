import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lunaris/services/database_service.dart';
import 'package:lunaris/shared_widgets.dart';
import 'package:lunaris/theme_provider.dart';
import 'package:provider/provider.dart';
// import 'movie_detail_screen.dart'; // No longer needed here

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final DatabaseService _dbService = DatabaseService();

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
            cardBg: LunarisColorsDark.cardBackground
          )
        : (
            accent1: LunarisColorsLight.accentViolet,
            accent2: LunarisColorsLight.accentMagenta,
            text: LunarisColorsLight.text,
            cardBg: LunarisColorsLight.cardBackground
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: NeonText(
              text: 'My Watchlist',
              gradientColors: [colors.accent1, colors.accent2],
              fontSize: 22,
            ),
          ),
          SliverFillRemaining(
            child: StreamBuilder<List<Movie>>(
              stream: _dbService.getWatchlistStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: TextStyle(color: colors.text)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.movie_filter_sharp,
                            color: colors.text.withOpacity(0.5), size: 60),
                        const SizedBox(height: 16),
                        Text(
                          "Your Watchlist is Empty",
                          style: TextStyle(
                              color: colors.text.withOpacity(0.8),
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "Add movies from the Home page.",
                          style: TextStyle(
                              color: colors.text.withOpacity(0.6),
                              fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final movies = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final Movie movie = movies[index];
                    return MovieCard(
                      movie: movie,
                      colors: colors,
                      height: 220,
                      width: 140,
                      isDarkMode: isDarkMode,
                      // --- UPDATED: Navigate to detail screen ---
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/details',
                          arguments: movie,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}