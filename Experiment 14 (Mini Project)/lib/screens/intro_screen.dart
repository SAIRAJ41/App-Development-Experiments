import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class IntroScreen extends StatefulWidget {
  final Widget child;
  
  const IntroScreen({super.key, required this.child});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;
  bool _showMainApp = false;
  bool _videoCompleted = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Show loading for a moment (like app initialization)
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      _controller = VideoPlayerController.asset('assets/intro_logo_screen.mp4');
      
      await _controller.initialize();
      
      if (mounted) {
        // Set looping to false
        _controller.setLooping(false);
        
        // Listen for video position changes
        _controller.addListener(_videoListener);
        
        setState(() {
          _isLoading = false;
          _isVideoInitialized = true;
        });
        
        // Start fade-in animation
        _fadeController.forward();
        
        // Play the video after a brief moment
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await _controller.play();
        }
        
        // Backup timer: navigate after video duration + 2 second pause
        final videoDuration = _controller.value.duration;
        if (videoDuration > Duration.zero) {
          Future.delayed(videoDuration + const Duration(seconds: 2, milliseconds: 500), () {
            if (!_hasNavigated && mounted) {
              debugPrint('Navigating via backup timer');
              _navigateToMain();
            }
          });
        } else {
          // If duration is zero, wait a bit and try again
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _controller.value.duration > Duration.zero) {
              final duration = _controller.value.duration;
              Future.delayed(duration + const Duration(seconds: 2, milliseconds: 500), () {
                if (!_hasNavigated && mounted) {
                  debugPrint('Navigating via delayed backup timer');
                  _navigateToMain();
                }
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing intro video: $e');
      // If video fails to load, skip to main app
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _navigateToMain();
        }
      }
    }
  }

  void _videoListener() {
    if (!mounted || _hasNavigated) return;
    
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    
    // Check if video has completed (position reached duration)
    if (duration > Duration.zero && position >= duration && !_videoCompleted) {
      _videoCompleted = true;
      debugPrint('Video completed - waiting 2 seconds before navigation');
      
      // Wait 2 seconds before navigating (pause at end)
      Future.delayed(const Duration(seconds: 2), () {
        if (!_hasNavigated && mounted) {
          _navigateToMain();
        }
      });
    }
  }

  void _navigateToMain() {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      
      // Fade out before navigating
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showMainApp = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show main app after video finishes
    if (_showMainApp) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player with fade animation
          if (_isVideoInitialized)
            FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                // Allow user to skip by tapping
                onTap: () {
                  if (!_hasNavigated && _isVideoInitialized) {
                    _navigateToMain();
                  }
                },
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            ),
          
          // Loading indicator (shown at start)
          if (_isLoading)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
