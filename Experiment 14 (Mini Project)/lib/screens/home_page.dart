import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lunaris/shared_widgets.dart';
import 'package:lunaris/theme_provider.dart';
import '../services/movie_service.dart';

//############################################################################
// 3. MAIN HOME SCREEN WIDGET
//############################################################################

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MovieService _movieService;
  late Future<List<Movie>> _trendingMovies;
  late Future<List<Movie>> _topRatedMovies;
  late Future<List<Movie>> _scifiHits;
  late Future<List<Movie>> _actionHits;
  late Future<List<Movie>> _comedyHits;

  final List<String> _trendingTitles = [
    "Dune",
    "Barbie",
    "Oppenheimer",
    "Mission: Impossible",
    "Spider-Man: Across the Spider-Verse",
  ];
  final List<String> _topRatedTitles = [
    "The Shawshank Redemption",
    "The Godfather",
    "The Dark Knight",
    "Pulp Fiction",
    "Forrest Gump",
  ];
  final List<String> _scifiHitsTitles = [
    "Blade Runner 2049",
    "Interstellar",
    "Inception",
    "The Matrix",
    "Avatar",
  ];
  final List<String> _actionHitsTitles = [
    "Mad Max: Fury Road",
    "The Dark Knight",
    "Gladiator",
    "Die Hard",
    "John Wick",
  ];
  final List<String> _comedyHitsTitles = [
    "Superbad",
    "Step Brothers",
    "Anchorman",
    "The Hangover",
    "Bridesmaids",
  ];

  @override
  void initState() {
    super.initState();
    _movieService = MovieService();
    _loadMovies();
  }

  void _loadMovies() {
    _trendingMovies = _movieService.fetchMovieList(_trendingTitles);
    _topRatedMovies = _movieService.fetchMovieList(
      _topRatedTitles,
      minRating: 8.5,
    );
    _scifiHits = _movieService.fetchMovieList(_scifiHitsTitles);
    _actionHits = _movieService.fetchMovieList(_actionHitsTitles);
    _comedyHits = _movieService.fetchMovieList(_comedyHitsTitles);
  }

  // --- THIS FUNCTION IS NO LONGER USED, all logic is on /details page ---
  // void showMovieModal(BuildContext context, Movie movie, dynamic colors) { ... }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode
        ? (
            accent1: LunarisColorsDark.accentCyan,
            accent2: LunarisColorsDark.accentMagenta,
            text: LunarisColorsDark.text,
            cardBg: LunarisColorsDark.cardBackground,
          )
        : (
            accent1: LunarisColorsLight.accentViolet,
            accent2: LunarisColorsLight.accentMagenta,
            text: LunarisColorsLight.text,
            cardBg: LunarisColorsLight.cardBackground,
          );

    return CustomScrollView(
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
            text: 'LUNARIS',
            gradientColors: [colors.accent1, colors.accent2],
          ),
        ),
        _buildMovieSection(
          title: "🔥 Trending Now",
          future: _trendingMovies,
          colors: colors,
          isDarkMode: isDarkMode,
        ),
        _buildMovieSection(
          title: "🌠 Top Rated",
          future: _topRatedMovies,
          colors: colors,
          isDarkMode: isDarkMode,
        ),
        _buildMovieSection(
          title: "🚀 Sci-Fi Hits",
          future: _scifiHits,
          colors: colors,
          isDarkMode: isDarkMode,
        ),
        _buildMovieSection(
          title: "💥 Action Hits",
          future: _actionHits,
          colors: colors,
          isDarkMode: isDarkMode,
        ),
        _buildMovieSection(
          title: "😂 Comedy Hits",
          future: _comedyHits,
          colors: colors,
          isDarkMode: isDarkMode,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildMovieSection({
    required String title,
    required Future<List<Movie>> future,
    required dynamic colors,
    required bool isDarkMode,
    double cardHeight = 220,
    double cardWidth = 140,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
            child: NeonText(
              text: title,
              gradientColors: [colors.accent1, colors.accent2],
              fontSize: 20,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: cardHeight,
            child: FutureBuilder<List<Movie>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ShimmerLoadingList(
                    cardHeight: cardHeight,
                    cardWidth: cardWidth,
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      snapshot.hasError
                          ? 'Connection lost in space 🌙'
                          : 'No movies found.',
                      style: TextStyle(color: colors.text.withOpacity(0.7)),
                    ),
                  );
                }

                final movies = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final Movie movie = movies[index];
                    return MovieCard(
                      movie: movie,
                      colors: colors,
                      height: cardHeight,
                      width: cardWidth,
                      isDarkMode: isDarkMode,
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
        ),
      ],
    );
  }
}
