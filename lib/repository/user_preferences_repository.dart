// lib/repository/user_preferences_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPreferencesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _preferencesCollection = 'user_preferences';

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection(_preferencesCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      }

      // Return defaults
      return {
        'theme': 'system', // system, light, dark
        'fontSize': 'normal',
        'highContrast': false,
        'reduceMotion': false,
        'notificationsEnabled': true,
      };
    } catch (e) {
      return {};
    }
  }

  // Save user preferences
  Future<void> saveUserPreferences({
    required String userId,
    String? theme,
    String? fontSize,
    bool? highContrast,
    bool? reduceMotion,
    bool? notificationsEnabled,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (theme != null) updates['theme'] = theme;
      if (fontSize != null) updates['fontSize'] = fontSize;
      if (highContrast != null) updates['highContrast'] = highContrast;
      if (reduceMotion != null) updates['reduceMotion'] = reduceMotion;
      if (notificationsEnabled != null) {
        updates['notificationsEnabled'] = notificationsEnabled;
      }

      await _firestore
          .collection(_preferencesCollection)
          .doc(userId)
          .set(updates, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save preferences: $e');
    }
  }
}

