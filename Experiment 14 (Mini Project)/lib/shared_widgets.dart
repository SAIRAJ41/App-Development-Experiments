import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart'; // Import theme colors
import 'services/database_service.dart'; // Import DatabaseService

//############################################################################
// 1. DATA MODEL (NOW LIVES HERE)
//############################################################################
class Movie {
  final String title;
  final String posterUrl;
  final String year;
  final String imdbID;
  final double rating;
  String? trailerId;

  Movie({
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.imdbID,
    this.rating = 0.0,
    this.trailerId,
  });

  // --- UPDATED: Factory to parse the OMDb API JSON ---
  factory Movie.fromOMDb(Map<String, dynamic> json) {
    
    String getPoster(dynamic poster) {
      if (poster is String && poster != 'N/A') {
        return poster;
      }
      return ''; 
    }

    String getYear(dynamic year) {
      if (year is String && year != 'N/A') {
        return year;
      }
      return 'N/A';
    }
    
    double getRating(dynamic imdbRating) {
      if (imdbRating is String && imdbRating != 'N/A') {
        return (double.tryParse(imdbRating) ?? 0.0);
      }
      return 0.0;
    }

    // --- THIS IS THE FIX ---
    // We must have a valid imdbID, otherwise the app will crash
    // when trying to use it as a document ID in Firestore.
    final String imdbID = json['imdbID'];
    if (imdbID.isEmpty) {
      throw Exception('Failed to parse movie: imdbID is missing or empty.');
    }
    // --- END OF FIX ---

    return Movie(
      imdbID: imdbID,
      title: json['Title'] ?? 'No Title',
      posterUrl: getPoster(json['Poster']),
      year: getYear(json['Year']),
      rating: getRating(json['imdbRating']),
      trailerId: null, // This will be fetched separately
    );
  }


  // Function to convert Firestore data to Movie object
  factory Movie.fromFirestore(Map<String, dynamic> firestoreData) {
    return Movie(
      title: firestoreData['title'] ?? 'No Title',
      posterUrl: firestoreData['posterUrl'] ?? '',
      year: firestoreData['year'] ?? 'N/A',
      imdbID: firestoreData['imdbID'] ?? '',
      rating: (firestoreData['rating'] as num?)?.toDouble() ?? 0.0,
      trailerId: firestoreData['trailerId'],
    );
  }

  // Function to convert Movie object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'posterUrl': posterUrl,
      'year': year,
      'imdbID': imdbID,
      'rating': rating,
      'trailerId': trailerId,
      'addedOn': FieldValue.serverTimestamp(),
    };
  }
}

//############################################################################
// 2. REUSABLE WIDGETS
//############################################################################

// --- RENAMED: AppBackground (Was AuroraBackground) ---
class AppBackground extends StatelessWidget {
  final bool isLightMode;
  const AppBackground({
    super.key,
    required this.isLightMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLightMode
              ? [
                  LunarisColorsLight.backgroundStart,
                  LunarisColorsLight.backgroundEnd
                ]
              : [
                  LunarisColorsDark.backgroundStart,
                  LunarisColorsDark.backgroundEnd
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}


// --- REMOVED: StaticParticlePainter ---


// --- Neon Text Widget ---
class NeonText extends StatelessWidget {
// ... (existing NeonText code) ...
  final String text;
  final List<Color> gradientColors;
  final double fontSize;
  final String fontFamily;
  const NeonText({
    super.key,
    required this.text,
    required this.gradientColors,
    this.fontSize = 24,
    this.fontFamily = 'Orbitron',
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: gradientColors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          shadows: [
            Shadow(
              color: gradientColors[0].withOpacity(0.5),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Glassmorphic Profile Icon ---
class GlassmorphicProfileIcon extends StatelessWidget {
// ... (existing GlassmorphicProfileIcon code) ...
  final VoidCallback onTap;
  final Widget child;
  const GlassmorphicProfileIcon({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(100.0),
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipOval(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Movie Card Widget ---
class MovieCard extends StatelessWidget {
// ... (existing MovieCard code) ...
  final Movie movie; // <-- UPDATED to use 'Movie' model
  final double height;
  final double width;
  final dynamic colors;
  final bool isDarkMode;
  final VoidCallback onTap;

  const MovieCard({
    super.key,
    required this.movie,
    required this.height,
    required this.width,
    required this.colors,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              isDarkMode
                  ? BoxShadow(
                      color: colors.accent1.withOpacity(0.25),
                      blurRadius: 15.0,
                      spreadRadius: 2.0,
                    )
                  : BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10.0,
                    )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  movie.posterUrl, // <-- Use new model field
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colors.cardBg,
                      child: Center(
                        child: Icon(
                          Icons.movie_creation_outlined,
                          color: colors.text.withOpacity(0.2),
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8)
                        ],
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: Text(
                    movie.title, // <-- Use new model field
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 8.0,
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12.0,
                  right: 12.0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 14),
                        const SizedBox(width: 4.0),
                        Text(
                          movie.rating.toStringAsFixed(1), // <-- Use new model field
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Shimmer Loading Widgets ---
class ShimmerLoadingList extends StatelessWidget {
// ... (existing ShimmerLoadingList code) ...
  final double cardHeight;
  final double cardWidth;
  const ShimmerLoadingList(
      {super.key, required this.cardHeight, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: 5,
        itemBuilder: (context, index) => ShimmerLoadingCard(
          height: cardHeight,
          width: cardWidth,
        ),
      ),
    );
  }
}

class ShimmerLoadingCard extends StatelessWidget {
// ... (existing ShimmerLoadingCard code) ...
  final double height;
  final double width;
  const ShimmerLoadingCard(
      {super.key, required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }
}

// --- Glassmorphic FAB ---
class GlassmorphicFAB extends StatefulWidget {
// ... (existing GlassmorphicFAB code) ...
  final Color pulseColor;
  final VoidCallback onTap;
  const GlassmorphicFAB(
      {super.key, required this.pulseColor, required this.onTap});

  @override
  State<GlassmorphicFAB> createState() => _GlassmorphicFABState();
}

class _GlassmorphicFABState extends State<GlassmorphicFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1.5,
                  color: Colors.white.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.pulseColor.withOpacity(0.5),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value / 4,
                  )
                ],
              ),
              child: child,
            );
          },
          child: InkWell(
            borderRadius: BorderRadius.circular(100.0),
            onTap: widget.onTap,
            child: const Center(
              child: Text(
                "🌙",
                style: TextStyle(fontSize: 24.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Premium Lounge Modal (as a Screen) ---
class PremiumLoungeScreen extends StatelessWidget {
// ... (existing PremiumLoungeScreen code) ...
  const PremiumLoungeScreen({super.key});

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
            bgStart: LunarisColorsDark.backgroundStart,
            bgEnd: LunarisColorsDark.backgroundEnd,
            cardBg: LunarisColorsDark.cardBackground
          )
        : (
            accent1: LunarisColorsLight.accentViolet,
            accent2: LunarisColorsLight.accentMagenta,
            text: LunarisColorsLight.text,
            bgStart: LunarisColorsLight.backgroundStart,
            bgEnd: LunarisColorsLight.backgroundEnd,
            cardBg: LunarisColorsLight.cardBackground
          );

    return Scaffold(
      body: Stack(
        children: [
          // --- UPDATED: Use AppBackground ---
          AppBackground(
            isLightMode: !isDarkMode,
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: NeonText(
                    text: 'Premium Lounge',
                    gradientColors: [colors.accent1, colors.accent2],
                    fontSize: 22,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: GlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "🌙",
                                style: TextStyle(fontSize: 48.0),
                              ),
                              const SizedBox(height: 16),
                              NeonText(
                                text: "Coming Soon",
                                gradientColors: [
                                  colors.accent1,
                                  colors.accent2
                                ],
                                fontSize: 24,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Unlock exclusive collections, ad-free streaming, and AI-powered recommendations.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: colors.text.withOpacity(0.8),
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              GradientButton(
                                text: "Join the Lunar Circle",
                                gradient: LinearGradient(
                                  colors: [colors.accent2, colors.accent1],
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- Glassmorphic Nav Bar ---
class GlassmorphicNavBar extends StatelessWidget {
// ... (existing GlassmorphicNavBar code) ...
  final int selectedIndex;
  final Function(int) onTap;
  final List<IconData> icons;
  final Color activeColor;
  final Color inactiveColor;

  const GlassmorphicNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.icons,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 80.0,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24.0)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(icons.length, (index) {
              final bool isActive = selectedIndex == index;
              return _NavBarItem(
                icon: icons[index],
                isActive: isActive,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
// ... (existing _NavBarItem code) ...
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 28.0,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(top: 4.0),
                height: 4.0,
                width: isActive ? 20.0 : 0.0,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2.0),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.7),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Circular Glow Avatar (for Profile) ---
class CircularGlowAvatar extends StatelessWidget {
// ... (existing CircularGlowAvatar code) ...
  final Widget child;
  final Color glowColor;
  const CircularGlowAvatar(
      {super.key, required this.child, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

// --- Glass Container (for Profile) ---
class GlassContainer extends StatelessWidget {
// ... (existing GlassContainer code) ...
  final Widget child;
  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- Gradient Button (for Profile) ---
class GradientButton extends StatelessWidget {
// ... (existing GradientButton code) ...
  final String text;
  final Gradient gradient;
  final VoidCallback onPressed;
  // --- THIS IS THE FIX ---
  final Widget? child; // Made child optional

  const GradientButton({
    super.key,
    required this.text,
    required this.gradient,
    required this.onPressed,
    this.child, // Added child to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(-5, 5),
          ),
          BoxShadow(
            color: (gradient.colors.last).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        // --- THIS IS THE FIX ---
        // If a child is provided (like a spinner), use it.
        // Otherwise, use the text.
        child: child ?? Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// --- Custom Divider (for Profile) ---
class CustomDivider extends StatelessWidget {
// ... (existing CustomDivider code) ...
  const CustomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      height: 1.0,
      indent: 16.0,
      endIndent: 16.0,
    );
  }
}

// --- MOVED TO SHARED WIDGETS ---
// This widget is now available to all pages
class WatchlistButton extends StatelessWidget {
  const WatchlistButton({
    super.key,
    required DatabaseService dbService,
    required this.movie,
    required this.colors,
  }) : _dbService = dbService;

  final DatabaseService _dbService;
  final Movie movie;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _dbService.isMovieInWatchlist(movie.imdbID),
      builder: (context, snapshot) {
        final bool isInWatchlist = snapshot.data ?? false;

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(
              isInWatchlist ? Icons.check : Icons.add,
              color: isInWatchlist ? colors.accent1 : colors.text,
            ),
            label: Text(
              isInWatchlist ? "ON MY WATCHLIST" : "ADD TO WATCHLIST",
              style: TextStyle(
                color: isInWatchlist ? colors.accent1 : colors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: isInWatchlist
                    ? colors.accent1
                    : colors.text.withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () {
              if (isInWatchlist) {
                _dbService.removeFromWatchlist(movie.imdbID);
              } else {
                _dbService.addToWatchlist(movie);
              }
            },
          ),
        );
      },
    );
  }
}


// --- Trailer Player Modal ---
void showTrailerModal(BuildContext context, String videoId) {
  YoutubePlayerController controller = YoutubePlayerController(
    initialVideoId: videoId,
    flags: const YoutubePlayerFlags(
      autoPlay: true,
      mute: false,
    ),
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: Colors.black,
          child: Wrap(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              YoutubePlayer(
                controller: controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: LunarisColorsDark.accentCyan,
                onEnded: (data) {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

//############################################################################
// PREMIUM PROMOTION AD DIALOG (Integrated Feature)
//############################################################################

/// Premium Promotion Ad Dialog Widget
class PremiumPromotionAd extends StatelessWidget {
  final String? title;
  final String? message;
  final String? actionText;

  const PremiumPromotionAd({
    super.key,
    this.title,
    this.message,
    this.actionText,
  });

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
            cardBg: LunarisColorsDark.cardBackground,
          )
        : (
            accent1: LunarisColorsLight.accentViolet,
            accent2: LunarisColorsLight.accentMagenta,
            text: LunarisColorsLight.text,
            cardBg: LunarisColorsLight.cardBackground,
          );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colors.accent1, colors.accent2],
                  ),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              NeonText(
                text: title ?? 'Upgrade to Premium',
                gradientColors: [colors.accent1, colors.accent2],
                fontSize: 24,
                fontFamily: 'Poppins',
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                message ??
                    'Upgrade to Premium for an ad-free experience and unlock exclusive features!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Features List
              _buildFeatureItem(
                icon: Icons.block,
                text: 'Ad-free experience',
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                icon: Icons.auto_awesome,
                text: 'AI Bot access',
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                icon: Icons.verified,
                text: 'Premium badge',
                colors: colors,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  // Dismiss Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: colors.text.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(
                          color: colors.text,
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Upgrade Button
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.accent1, colors.accent2],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent1.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/premium_lounge');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          actionText ?? 'Upgrade Now',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required dynamic colors,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: colors.accent1,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: colors.text,
            fontFamily: 'Poppins',
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

/// Helper function to check if user is premium
Future<bool> _checkIfUserIsPremium() async {
  final dbService = DatabaseService();
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null || user.isAnonymous) return false;
  
  try {
    final doc = await dbService.getUserProfile();
    if (!doc.exists) return false;
    
    final data = doc.data();
    final bool isPremium = data?['isPremium'] ?? false;
    final bool isAdmin = data?['isAdmin'] ?? false;
    return isPremium || isAdmin;
  } catch (e) {
    debugPrint('Error checking premium status: $e');
    return false;
  }
}

/// Helper function to show premium promotion ad (only for non-premium users)
Future<void> showPremiumPromotionAd(
  BuildContext context, {
  String? title,
  String? message,
  String? actionText,
}) async {
  // Check if user is premium - don't show ads for premium users
  final isPremium = await _checkIfUserIsPremium();
  if (isPremium) {
    debugPrint('User is premium, skipping promotion ad');
    return;
  }

  // Show promotional ad
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PremiumPromotionAd(
        title: title,
        message: message,
        actionText: actionText,
      ),
    );
  }
}