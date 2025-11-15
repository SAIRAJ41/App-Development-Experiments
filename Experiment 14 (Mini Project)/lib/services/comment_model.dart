import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String text;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final Timestamp timestamp;

  Comment({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.timestamp,
  });

  /// A safer factory for parsing Firestore data.
  /// This handles missing fields and null values without crashing.
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    // Get the data object, or an empty map if it's null (which it shouldn't be
    // from a query, but this is safer)
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Comment(
      id: doc.id,
      // Use 'as String?' for safe casting, then '??' for fallback
      text: data['text'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'User',
      // This field is already nullable, so 'as String?' is perfect
      userPhotoUrl: data['userPhotoUrl'] as String?,
      // This is the most likely fix:
      // Cast to 'Timestamp?' (nullable) first, then provide a fallback.
      timestamp: (data['timestamp'] as Timestamp?) ?? Timestamp.now(),
    );
  }
}