import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For API calls
import '../services/const.dart'; // Import your API keys
import 'package:lunaris/shared_widgets.dart'; // Import Movie model

//############################################################################
// 1. YOUTUBE API SERVICE (No Change)
//############################################################################

class YouTubeService {
  static const String _baseUrl =
      "https://www.googleapis.com/youtube/v3/search";

  Future<String?> fetchTrailerId(String movieTitle) async {
    if (youtubeApiKey == "YOUR_YOUTUBE_KEY_HERE") {
      debugPrint("--- YouTubeService Error: API Key is not set in lib/constants.dart ---");
      return null;
    }

    final String query = Uri.encodeComponent('$movieTitle official trailer');
    final String url =
        '$_baseUrl?part=snippet&q=$query&key=$youtubeApiKey&type=video&maxResults=1';

    try {
      final response = await http.get(Uri.parse(url));
      
      // --- ADDED: Better logging ---
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final trailerId = data['items'][0]['id']['videoId'];
          debugPrint("+++ YouTubeService Success: Found trailer $trailerId for $movieTitle");
          return trailerId;
        } else {
          debugPrint("--- YouTubeService Warning: 200 OK but no items found for $movieTitle");
          return null;
        }
      } else {
        // This will print the error from Google (e.g., "API Key Invalid" or "Quota Exceeded")
        debugPrint("--- YouTubeService Error: API call failed (${response.statusCode}) ---");
        debugPrint("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("--- YouTubeService Error: Failed to fetch trailer for $movieTitle: $e");
      return null;
    }
  }
}

//############################################################################
// 2. OMDb MOVIE SERVICE (Replaces RapidAPI)
//############################################################################

class MovieService {
  // Use the OMDb API
  final String _baseUrl = "https://www.omdbapi.com/";
  // --- REMOVED: YouTubeService instance, it will be called from the UI ---

  // --- Check API Keys ---
  bool _areKeysMissing() {
    if (omdbApiKey.isEmpty) {
      debugPrint("OMDb API Key is not set in lib/constants.dart.");
      return true;
    }
    return false;
  }

  // --- PRIVATE: Fetches full details (including rating) for one movie ---
  Future<Movie?> _fetchMovieDetails(String imdbID) async {
    if (_areKeysMissing()) return null;

    final String url = '$_baseUrl?apikey=$omdbApiKey&i=$imdbID';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data['Response'] == 'True') {
          // Use the OMDb parser from shared_widgets
          return Movie.fromOMDb(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching movie details: $e");
      return null;
    }
  }

  // --- Used by HomeScreen ---
  Future<List<Movie>> fetchMovieList(List<String> titles,
      {double minRating = 0.0}) async {
    if (_areKeysMissing()) return [];
    
    List<Movie> movies = [];

    for (String title in titles) {
      // OMDb search endpoint (s=)
      final String url =
          '$_baseUrl?apikey=$omdbApiKey&s=${Uri.encodeComponent(title)}&type=movie';
      
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['Response'] == 'True' && data['Search'] != null) {
            
            // Get the first result from the search
            final movieSearchResult = data['Search'][0];
            final String imdbID = movieSearchResult['imdbID'];
            
            // Fetch its full details to get the rating
            final Movie? movie = await _fetchMovieDetails(imdbID);
            
            if (movie != null && movie.rating >= minRating) {
              // We no longer fetch the trailer here
              movies.add(movie);
            }
          } else if (data['Response'] == 'False') {
             debugPrint("OMDb Error for '$title': ${data['Error']}");
          }
        }
      } catch (e) {
        debugPrint("Error fetching movie list for '$title': $e");
      }
      // OMDb has a limit of 1000 calls/day. A small delay is respectful.
      await Future.delayed(const Duration(milliseconds: 100)); 
    }
    return movies;
  }

  // --- PUBLIC: Search function (Corrected Endpoint) ---
  Future<List<Movie>> searchMovies(String query) async {
    if (_areKeysMissing() || query.isEmpty) return [];

    final String url =
        '$_baseUrl?apikey=$omdbApiKey&s=${Uri.encodeComponent(query)}&type=movie';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data['Response'] == 'True' && data['Search'] != null) {
          final List<dynamic> searchResults = data['Search'];
          
          List<Movie> movies = [];
          List<Future> detailFutures = [];

          // We must fetch full details for each search result
          for (var result in searchResults.take(6)) { // Limit to 6 results
            if (result is Map<String, dynamic> && result['imdbID'] != null) {
              final String imdbID = result['imdbID'];
              
              // Add the detail fetch to a list of futures
              detailFutures.add(
                _fetchMovieDetails(imdbID).then((fullMovie) async {
                  if (fullMovie != null) {
                    // We no longer fetch the trailer here
                    movies.add(fullMovie);
                  }
                })
              );
            }
          }
          // Wait for all detail/trailer fetches to complete
          await Future.wait(detailFutures);
          return movies;
        } else if (data['Response'] == 'False') {
           debugPrint("OMDb Error: ${data['Error']}");
        }
      } else {
        debugPrint("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error in searchMovies: $e");
    }
    return []; // Return empty on any error
  }
}