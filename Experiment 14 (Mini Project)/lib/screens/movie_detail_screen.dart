import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// --- Local Imports ---
import '../services/database_service.dart';
import '../services/movie_service.dart'; // Assumes YouTubeService is in here
import '../shared_widgets.dart'; // Assumes Movie model, WatchlistButton, GlassContainer, etc.
import '../theme_provider.dart';
import '../services/comment_model.dart'; // Assumes Comment model is here

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _commentController = TextEditingController();
  
  // Gets the current user from FirebaseAuth
  User? get _user => FirebaseAuth.instance.currentUser;

  bool _isFetchingTrailer = false;
  bool _hasShownAd = false; // Track if ad has been shown for this trailer
  late Movie _movie; // Local copy to hold trailer ID

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    
    debugPrint("--- Opening Detail Screen for Movie ID: '${_movie.imdbID}' ---");
    
    // Attempt to load trailer if it doesn't already exist
    if (_movie.trailerId == null || _movie.trailerId!.isEmpty) {
      _fetchTrailerOnLoad();
    }
  }

  // Fetch the trailer ID from YouTubeService
  void _fetchTrailerOnLoad() async {
    // IMPORTANT: Make sure you have added your YouTube API Key to the
    // YouTubeService class in your 'movie_service.dart' file!
    
    setState(() => _isFetchingTrailer = true);
    try {
      final String? trailerId = await YouTubeService().fetchTrailerId(_movie.title);
      if (mounted) {
        setState(() {
          _isFetchingTrailer = false;
          if (trailerId != null) {
            _movie.trailerId = trailerId;
            debugPrint("+++ YouTubeService Success: Found trailer $trailerId");
          } else {
            debugPrint("--- YouTubeService: No trailer found for ${_movie.title}");
          }
        });
      }
    } catch (e) {
      debugPrint("--- YouTubeService Error: $e");
      if (mounted) {
        setState(() => _isFetchingTrailer = false);
      }
    }
  }

  // --- Send Comment to Firebase ---
  void _postComment() {
    // Stop if text is empty, user is null, or movie ID is invalid
    if (_commentController.text.trim().isEmpty || _user == null) return;
    if (_movie.imdbID.isEmpty) return;

    _dbService.addComment(
      _movie.imdbID,
      _commentController.text.trim(),
      _user!.displayName ?? "Anonymous",
      _user!.photoURL,
    );
    _commentController.clear();
    FocusScope.of(context).unfocus(); // Close keyboard
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    
    // Defines the color palette based on the theme
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
      extendBodyBehindAppBar: true, // Allows content to scroll behind app bar
      backgroundColor: Colors.transparent, // Uses AppBackground for gradient
      body: Stack(
        children: [
          // Your consistent app background
          AppBackground(isLightMode: !isDarkMode),
          
          // Scrollable content
          CustomScrollView(
            slivers: [
              // --- 1. The Top Section (Trailer Player) ---
              SliverAppBar(
                expandedHeight: 250.0, // Height for the trailer
                backgroundColor: Colors.black, // Background for the player
                elevation: 0,
                pinned: true, // App bar stays visible as you scroll
                leading: Container(
                  margin: const EdgeInsets.all(8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24.0),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: GlassContainer(
                          child: Icon(
                            Icons.arrow_back,
                            color: colors.text,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildTrailerSection(colors),
                ),
              ),

              // --- 2. Movie Details & Buttons (Below the player) ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Movie Title
                      NeonText(
                        text: _movie.title,
                        gradientColors: [colors.accent1, colors.accent2],
                        fontSize: 28,
                        fontFamily: 'Poppins',
                      ),
                      const SizedBox(height: 8),
                      
                      // Rating and Year Row
                      Row(
                        children: [
                          Icon(Icons.star_rate_rounded,
                              color: colors.accent1, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "${_movie.rating.toStringAsFixed(1)}/10",
                            style: TextStyle(
                                color: colors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _movie.year,
                            style: TextStyle(
                                color: colors.text.withOpacity(0.6),
                                fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Action Buttons (Like & Watchlist) ---
                      _buildActionRow(colors),

                      const SizedBox(height: 32),

                      // --- 3. Comments Section ---
                      _buildCommentSection(colors),

                      // Bottom padding to ensure content isn't hidden
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the YouTube player or a fallback UI
  Widget _buildTrailerSection(dynamic colors) {
    if (_movie.trailerId != null && _movie.trailerId!.isNotEmpty) {
      // Show promotional ad before playing trailer for non-premium users (only once per trailer)
      if (!_hasShownAd) {
        _hasShownAd = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            await showPremiumPromotionAd(
              context,
              title: 'Enjoying the Trailer?',
              message: 'Upgrade to Premium to watch trailers ad-free and unlock exclusive features!',
            );
          }
        });
      }
      
      // If we have a trailer ID, show the player
      return YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: _movie.trailerId!,
          flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
        ),
        showVideoProgressIndicator: true,
        progressIndicatorColor: colors.accent1,
      );
    }

    // Fallback UI while fetching or if no trailer is found
    return Center(
      child: _isFetchingTrailer
          ? CircularProgressIndicator(color: colors.accent1)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_creation_outlined,
                    color: colors.text.withOpacity(0.6), size: 40),
                const SizedBox(height: 8),
                Text('Trailer Not Found.', style: TextStyle(color: colors.text)),
              ],
            ),
    );
  }

  /// Builds the Like button, Like count, and Watchlist button
  Widget _buildActionRow(dynamic colors) {
    // --- SAFETY CHECK 1: INVALID MOVIE ID ---
    // If the movie has no ID, we can't interact with Firestore.
    if (_movie.imdbID.trim().isEmpty) {
      return Text(
        "Interactive features unavailable for this title.",
        style: TextStyle(
            color: colors.text.withOpacity(0.5), fontStyle: FontStyle.italic),
      );
    }

    // --- SAFETY CHECK 2: GUEST USER ---
    // If user is not logged in, show disabled buttons.
    if (_user == null || _user!.isAnonymous) {
      return Row(
        children: [
          // Disabled Like Button
          GlassContainer(
            child: IconButton(
              icon: Icon(Icons.favorite_border,
                  color: colors.text.withOpacity(0.5)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please log in to like movies.")),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Likes (Log in)",
            style: TextStyle(color: colors.text.withOpacity(0.5)),
          ),
          const Spacer(),
          // Disabled Watchlist Button
          SizedBox(
            width: 200,
            child: Opacity(
              opacity: 0.5,
              child: OutlinedButton.icon(
                icon: Icon(Icons.add, color: colors.text),
                label: Text("ADD TO WATCHLIST",
                    style: TextStyle(color: colors.text)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.text.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please log in to use your watchlist.")),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // --- LOGGED-IN USER: Show functional buttons ---
    return Row(
      children: [
        // --- Like Button ---
        StreamBuilder<bool>(
          stream: _dbService.isMovieLiked(_movie.imdbID),
          builder: (context, snapshot) {
            final isLiked = snapshot.data ?? false;
            return GlassContainer(
              child: IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? colors.accent2 : colors.text,
                ),
                onPressed: () async {
                  // Check if user is logged in
                  if (_user == null || _user!.isAnonymous) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please log in to like movies.")),
                    );
                    return;
                  }
                  
                  // Check if movie ID is valid
                  if (_movie.imdbID.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid movie ID.")),
                    );
                    return;
                  }
                  
                  try {
                    // Pass the full '_movie' object as required by the new
                    // database_service.dart file for the admin panel.
                    if (isLiked) {
                      await _dbService.unlikeMovie(_movie.imdbID);
                    } else {
                      await _dbService.likeMovie(_movie);
                    }
                  } catch (e) {
                    debugPrint("Error toggling like: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to ${isLiked ? 'unlike' : 'like'} movie: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        
        // --- Like Count ---
        StreamBuilder<int>(
          stream: _dbService.getLikeCount(_movie.imdbID),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Text(
              "$count Likes",
              style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
            );
          },
        ),
        const Spacer(),
        
        // --- Watchlist Button (from shared_widgets) ---
        SizedBox(
          width: 200, // Give it a max width
          child: WatchlistButton(
            dbService: _dbService,
            movie: _movie,
            colors: colors,
          ),
        ),
      ],
    );
  }

  /// Builds the Comment input field and the list of comments
  Widget _buildCommentSection(dynamic colors) {
    // --- SAFETY CHECK: INVALID MOVIE ID ---
    if (_movie.imdbID.trim().isEmpty) {
      return const SizedBox.shrink(); // Don't show anything
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeonText(
          text: "Comments",
          gradientColors: [colors.accent1, colors.accent2],
          fontSize: 20,
          fontFamily: 'Poppins',
        ),
        const SizedBox(height: 16),
        
        // --- Comment Input Field ---
        if (_user != null && !_user!.isAnonymous)
          // Show input field only for logged-in users
          GlassContainer(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _commentController,
                style: TextStyle(color: colors.text),
                decoration: InputDecoration(
                  hintText: "Add a public comment...",
                  hintStyle: TextStyle(color: colors.text.withOpacity(0.5)),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send, color: colors.accent1),
                    onPressed: _postComment,
                  ),
                ),
              ),
            ),
          )
        else
          // Show for guests
          Text(
            "Log in to post comments.",
            style: TextStyle(color: colors.text.withOpacity(0.5)),
          ),
        const SizedBox(height: 24),

        // --- Comments List from Firestore ---
        StreamBuilder<List<Comment>>(
          stream: _dbService.getComments(_movie.imdbID),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "Be the first to comment!",
                  style: TextStyle(color: colors.text.withOpacity(0.7)),
                ),
              );
            }
            
            final comments = snapshot.data!;
            
            return ListView.builder(
              itemCount: comments.length,
              shrinkWrap: true, // Needs this inside a CustomScrollView
              physics: const NeverScrollableScrollPhysics(), // Needs this
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User's profile picture or initial
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        backgroundImage: comment.userPhotoUrl != null
                            ? NetworkImage(comment.userPhotoUrl!)
                            : null,
                        child: comment.userPhotoUrl == null
                            ? Text(
                                comment.userName.isNotEmpty
                                    ? comment.userName[0].toUpperCase()
                                    : "?",
                                style: TextStyle(color: colors.text),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      
                      // User's name and comment text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.userName,
                              style: TextStyle(
                                color: colors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment.text,
                              style: TextStyle(
                                color: colors.text.withOpacity(0.9),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}