import 'dart:ui';
import 'package:flutter/material.dart';
// import 'package:lunaris/services/database_service.dart'; // <-- REMOVED
import 'package:lunaris/services/movie_service.dart';
import 'package:lunaris/theme_provider.dart';
import 'package:provider/provider.dart';
import '../shared_widgets.dart';
// import 'movie_detail_screen.dart'; // No longer needed here

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MovieService _movieService = MovieService();
  // final DatabaseService _dbService = DatabaseService(); // <-- REMOVED
  final TextEditingController _searchController = TextEditingController();

  Future<List<Movie>>? _searchFuture;
  String _currentQuery = "";
  bool _isLoading = false;

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchFuture = null;
        _currentQuery = "";
      });
      return;
    }
    setState(() {
      _currentQuery = query;
      _isLoading = true;
      _searchFuture = _movieService.searchMovies(query);
      
      _searchFuture!.whenComplete(() {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    });
  }

  // --- REMOVED: _showMovieModal ---

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
            title: Container(
              height: 44,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: colors.text, fontSize: 16),
                cursorColor: colors.accent1,
                decoration: InputDecoration(
                  hintText: 'Search movies (e.g. "Dune")...',
                  hintStyle: TextStyle(
                    color: colors.text.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  prefixIcon:
                      Icon(Icons.search, color: colors.accent1, size: 20),
                  suffixIcon: _currentQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              color: colors.text.withOpacity(0.5), size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch("");
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22.0),
                    borderSide: BorderSide(color: colors.accent1, width: 1.5),
                  ),
                ),
                onSubmitted: (query) {
                  _performSearch(query);
                },
              ),
            ),
          ),
          
          _buildBody(colors, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildBody(dynamic colors, bool isDarkMode) {
    if (_searchFuture == null && !_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_sharp,
                  color: colors.text.withOpacity(0.5), size: 60),
              const SizedBox(height: 16),
              Text(
                "Find Your Next Movie",
                style: TextStyle(
                    color: colors.text.withOpacity(0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                "Search by title.",
                style:
                    TextStyle(color: colors.text.withOpacity(0.6), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return FutureBuilder<List<Movie>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'Connection lost in space 🌙',
                style: TextStyle(color: colors.text.withOpacity(0.7)),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      color: colors.text.withOpacity(0.5), size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'No Results Found',
                    style: TextStyle(
                        color: colors.text.withOpacity(0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Try checking the spelling for "$_currentQuery"',
                    style: TextStyle(
                        color: colors.text.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          final movies = snapshot.data!;
          return SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.7, 
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final Movie movie = movies[index];
                  return MovieCard(
                    movie: movie,
                    colors: colors,
                    height: 240, 
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
                childCount: movies.length,
              ),
            ),
          );
        }

        return const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
    );
  }
}

// --- REMOVED: _WatchlistButton (moved to shared_widgets.dart) ---