import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // 1. Pick an Image
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // 2. Upload the Image and Update Profile
  Future<String?> uploadProfileImage(File imageFile) async {
    if (_userId == null) {
      throw Exception("User not authenticated");
    }

    try {
      // Create a reference to the file
      final ref = _storage.ref().child('profile_images').child(_userId!);
      
      // Upload the file
      UploadTask uploadTask = ref.putFile(imageFile);
      
      // Get the download URL
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 3. Update the FirebaseAuth user's photoURL
      await _auth.currentUser?.updatePhotoURL(downloadUrl);
      
      // 4. Reload the user to get the updated photoURL
      await _auth.currentUser?.reload();
      
      return downloadUrl;

    } catch (e) {
      debugPrint("Error uploading profile image: $e");
      rethrow; // Re-throw so the calling code can handle it properly
    }
  }
}