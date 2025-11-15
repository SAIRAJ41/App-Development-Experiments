import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared_widgets.dart';
import 'comment_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- USER ID HELPERS ---
  String? get currentUserId => _auth.currentUser?.uid;
  String? get _userId => _auth.currentUser?.uid;

  bool _isInvalid(String? s) => s == null || s.trim().isEmpty;
  String _clean(String s) => s.trim();

  // --- FIRESTORE PATHS ---
  String? get _userBasePath {
    final uid = _userId;
    if (_isInvalid(uid)) return null;
    const appId = 'default-app-id';
    return 'artifacts/$appId/users/$uid';
  }

  String get _publicBasePath {
    const appId = 'default-app-id';
    return 'artifacts/$appId/movies';
  }

  String get _usersCollectionPath {
    const appId = 'default-app-id';
    return 'artifacts/$appId/users';
  }

  // --- PREMIUM FEATURES ---
  Stream<bool> isUserPremium() {
    final basePath = _userBasePath;
    if (basePath == null) return Stream.value(false);
    return _db
        .doc(basePath)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data()!,
          toFirestore: (map, _) => map,
        )
        .snapshots()
        .map((snap) {
      final data = snap.data();
      return data?['isPremium'] ?? false;
    });
  }

  Future<bool> _checkUserPremiumStatus() async {
    final basePath = _userBasePath;
    if (basePath == null) return false;

    final doc = await _db
        .doc(basePath)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (map, _) => map,
        )
        .get();

    final data = doc.data();
    final bool isPremium = data?['isPremium'] ?? false;
    final bool isAdmin = data?['isAdmin'] ?? false;
    // Admins automatically get premium privileges
    return isPremium || isAdmin;
  }

  Stream<int> getWatchlistCount() {
    final basePath = _userBasePath;
    if (basePath == null) return Stream.value(0);
    return _db
        .collection('$basePath/watchlist')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // --- ADMIN FEATURES ---
  Stream<bool> isUserAdmin() {
    final basePath = _userBasePath;
    if (basePath == null) return Stream.value(false);
    return _db
        .doc(basePath)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data()!,
          toFirestore: (map, _) => map,
        )
        .snapshots()
        .map((snap) {
      final data = snap.data();
      return data?['isAdmin'] ?? false;
    });
  }

  // Returns all users (both premium and non-premium) without any filtering
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return _db
        .collection(_usersCollectionPath)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data()!,
          toFirestore: (map, _) => map,
        )
        .snapshots();
  }

  Future<void> setPremiumStatus(String userId, bool isPremium) {
    final userDocRef = _db.doc('$_usersCollectionPath/$userId');
    return userDocRef.set({
      'isPremium': isPremium,
    }, SetOptions(merge: true));
  }

  Stream<List<Movie>> getUserWatchlist(String userId) {
    if (_isInvalid(userId)) return Stream.value([]);
    final path = '$_usersCollectionPath/$userId/watchlist';
    return _db
        .collection(path)
        .orderBy('addedOn', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Movie.fromFirestore(d.data())).toList());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserLikes(String userId) {
    if (_isInvalid(userId)) return Stream.empty();
    debugPrint("Fetching likes for user: $userId");

    return _db
        .collectionGroup('likes')
        .where('userId', isEqualTo: userId)
        .orderBy('likedOn', descending: true)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data()!,
          toFirestore: (map, _) => map,
        )
        .snapshots();
  }

  Stream<List<Comment>> getUserComments(String userId) {
    if (_isInvalid(userId)) return Stream.value([]);
    debugPrint("Fetching comments for user: $userId");

    return _db
        .collectionGroup('comments')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Comment.fromFirestore(d)).toList());
  }

  // --- WATCHLIST ---
  Future<void> addToWatchlist(Movie movie) async {
    final basePath = _userBasePath;
    if (basePath == null || _isInvalid(movie.imdbID)) return;

    final cleanId = _clean(movie.imdbID);
    final watchlistRef = _db.collection('$basePath/watchlist');

    return _db.runTransaction((transaction) async {
      final bool isPremium = await _checkUserPremiumStatus();

      if (!isPremium) {
        final watchlistSnapshot = await watchlistRef.count().get();
        final count = watchlistSnapshot.count ?? 0;
        if (count >= 5) {
          throw Exception(
              "Watchlist full. Upgrade to Premium for unlimited movies!");
        }
      }

      final docRef = watchlistRef.doc(cleanId);
      transaction.set(docRef, movie.toJson());
    });
  }

  Future<void> removeFromWatchlist(String imdbID) async {
    final basePath = _userBasePath;
    if (basePath == null || _isInvalid(imdbID)) return;
    final cleanId = _clean(imdbID);
    await _db.collection('$basePath/watchlist').doc(cleanId).delete();
  }

  Stream<bool> isMovieInWatchlist(String imdbID) {
    final basePath = _userBasePath;
    if (basePath == null || _isInvalid(imdbID)) return Stream.value(false);
    final cleanId = _clean(imdbID);
    return _db
        .collection('$basePath/watchlist')
        .doc(cleanId)
        .snapshots()
        .map((s) => s.exists);
  }

  Stream<List<Movie>> getWatchlistStream() {
    final basePath = _userBasePath;
    if (basePath == null) return Stream.value([]);

    return _db
        .collection('$basePath/watchlist')
        .orderBy('addedOn', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Movie.fromFirestore(d.data())).toList());
  }

  // --- PROFILE ---
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() {
    final basePath = _userBasePath;
    if (basePath == null) throw Exception("User not logged in");
    return _db
        .doc(basePath)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data()!,
          toFirestore: (map, _) => map,
        )
        .get();
  }

  Stream<DocumentSnapshot<Object?>> getUserProfileStream() {
    final basePath = _userBasePath;
    if (basePath == null) return Stream.empty();
    
    // Use snapshots without converter to avoid errors for anonymous users
    // The profile page will handle null data gracefully
    return _db.doc(basePath).snapshots();
  }

  // *** THIS IS THE CORRECTED FUNCTION ***
  Future<void> updateUserData({
    String? displayName, // <-- It expects 'displayName'
    DateTime? birthday,
    String? email,
    String? photoURL,
    // <-- There is NO 'required String name'
  }) async {
    final basePath = _userBasePath;
    if (basePath == null) return;

    final doc = await _db.doc(basePath).get();
    final bool documentExists = doc.exists;

    final Map<String, dynamic> dataToUpdate = {
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // It uses the 'displayName' parameter here
    if (displayName != null) { 
      dataToUpdate['displayName'] = displayName;
      if (_auth.currentUser?.displayName != displayName) {
        await _auth.currentUser?.updateDisplayName(displayName); 
      }
    }

    if (email != null) {
      dataToUpdate['email'] = email;
    }

    if (birthday != null) {
      dataToUpdate['birthday'] = Timestamp.fromDate(birthday);
    }

    if (photoURL != null) {
      dataToUpdate['photoURL'] = photoURL;
    }

    // Use update() if document exists (uses the update rule which explicitly allows photoURL)
    // Use set() with merge if document doesn't exist (uses the write rule for creation)
    if (documentExists) {
      await _db.doc(basePath).update(dataToUpdate);
    } else {
      // For new documents, include isPremium and isAdmin set to false
      dataToUpdate['isPremium'] = false;
      dataToUpdate['isAdmin'] = false;
      await _db.doc(basePath).set(dataToUpdate, SetOptions(merge: true));
    }
  }
  
  // --- LIKES ---
  Stream<bool> isMovieLiked(String imdbID) {
    final uid = _userId;
    if (_isInvalid(uid) || _isInvalid(imdbID)) {
      return Stream.value(false);
    }
    final cleanId = _clean(imdbID);
    final likeRef = _db.doc('$_publicBasePath/$cleanId/likes/$uid');
    return likeRef.snapshots().map((snapshot) => snapshot.exists);
  }

  Stream<int> getLikeCount(String imdbID) {
    if (_isInvalid(imdbID)) {
      return Stream.value(0);
    }
    final cleanId = _clean(imdbID);
    final movieRef = _db.doc('$_publicBasePath/$cleanId');

    return movieRef
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? {},
          toFirestore: (map, _) => map,
        )
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      return data?['likeCount'] ?? 0;
    });
  }

  Future<void> likeMovie(Movie movie) async {
    final uid = _userId;
    if (_isInvalid(uid) || _isInvalid(movie.imdbID)) return;

    final cleanId = _clean(movie.imdbID);
    final movieRef = _db.doc('$_publicBasePath/$cleanId');
    final likeRef = _db.doc('$_publicBasePath/$cleanId/likes/$uid');

    return _db.runTransaction((tx) async {
      final movieSnapshot = await tx.get(movieRef);

      tx.set(likeRef, {
        'likedOn': FieldValue.serverTimestamp(),
        'userId': uid,
        'movieId': movie.imdbID,
        'movieTitle': movie.title,
        'posterUrl': movie.posterUrl,
      });

      if (movieSnapshot.exists) {
        tx.update(movieRef, {'likeCount': FieldValue.increment(1)});
      } else {
        tx.set(movieRef, {'likeCount': 1});
      }
    });
  }

  Future<void> unlikeMovie(String imdbID) async {
    final uid = _userId;
    if (_isInvalid(uid) || _isInvalid(imdbID)) return;

    final cleanId = _clean(imdbID);
    final movieRef = _db.doc('$_publicBasePath/$cleanId');
    final likeRef = _db.doc('$_publicBasePath/$cleanId/likes/$uid');

    return _db.runTransaction((tx) async {
      final movieSnapshot = await tx.get(movieRef);
      tx.delete(likeRef);
      if (movieSnapshot.exists &&
          (movieSnapshot.data() as Map<String, dynamic>)['likeCount'] > 0) {
        tx.update(movieRef, {'likeCount': FieldValue.increment(-1)});
      }
    });
  }

  // --- COMMENTS ---
  Stream<List<Comment>> getComments(String imdbID) {
    if (_isInvalid(imdbID)) return Stream.value([]);
    final cleanId = _clean(imdbID);
    return _db
        .collection('$_publicBasePath/$cleanId/comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Comment.fromFirestore(d)).toList());
  }

  Future<void> addComment(
      String imdbID, String text, String userName, String? photo) async {
    final uid = _userId;
    if (_isInvalid(uid) || _isInvalid(imdbID)) return;

    final cleanId = _clean(imdbID);
    await _db.collection('$_publicBasePath/$cleanId/comments').add({
      'text': text,
      'userId': uid,
      'userName': userName,
      'userPhotoUrl': photo,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // *** This function is now included ***
  Future<void> deleteComment(String imdbID, String commentId) async {
    // No need to check user ID here, Firestore Rules will handle it.
    if (_isInvalid(imdbID) || _isInvalid(commentId)) return;

    final cleanId = _clean(imdbID);
    final commentRef =
        _db.doc('$_publicBasePath/$cleanId/comments/$commentId');

    await commentRef.delete();
  }
}