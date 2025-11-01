// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the users collection
  CollectionReference get _usersRef => _firestore.collection('users');

  /// Save user info (create or update)
  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
    String? imageUrl,
  }) async {
    try {
      await _usersRef.doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'imageUrl': imageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge keeps existing fields if updating
      print("✅ User data saved successfully.");
    } catch (e) {
      print("⚠️ Error saving user data: $e");
      rethrow;
    }
  }

  /// Fetch user data by UID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("⚠️ Error fetching user data: $e");
      return null;
    }
  }

  /// Stream user data (auto updates when changed)
  Stream<Map<String, dynamic>?> streamUserData(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    });
  }

  /// Update a specific field (like imageUrl)
  Future<void> updateField(String uid, String field, dynamic value) async {
    try {
      await _usersRef.doc(uid).update({field: value});
      print("✅ Updated $field for user $uid");
    } catch (e) {
      print("⚠️ Error updating $field: $e");
    }
  }

  /// Delete user document (only if needed, e.g. account deletion)
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
      print("🗑️ User $uid deleted successfully.");
    } catch (e) {
      print("⚠️ Error deleting user: $e");
    }
  }

  /// Save data for currently logged-in user (shortcut)
  Future<void> saveCurrentUser({
    required String name,
    required String email,
    String? imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await saveUserData(uid: user.uid, name: name, email: email, imageUrl: imageUrl);
  }
}
