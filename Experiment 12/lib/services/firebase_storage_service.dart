import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage and returns the download URL
  Future<String?> uploadFile({
    required File file,
    required String path, // e.g. 'profile_pics' or 'uploads'
    String? customName,   // optional: use a specific name
  }) async {
    try {
      final fileName = customName ?? const Uuid().v4();
      final ref = _storage.ref().child('$path/$fileName.jpg');

      // Upload the file
      await ref.putFile(file);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("⚠️ Upload failed: $e");
      return null;
    }
  }

  /// Deletes a file from Firebase Storage by its URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print("⚠️ Delete failed: $e");
    }
  }

  /// Returns a reference URL for a given path
  Future<String?> getFileUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print("⚠️ Could not fetch file URL: $e");
      return null;
    }
  }
}
