// lib/repository/user_repository.dart
import '../backend/firestore_service.dart';

class UserRepository {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> saveOnboardingData({
    required String uid,
    String? displayName,
    String? phone,
    String? grade,
    String? interest,
  }) async {
    await _firestoreService.updateUserProfile(
      uid: uid,
      displayName: displayName,
      phone: phone,
      grade: grade,
      interest: interest,
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) {
    return _firestoreService.getUserProfile(uid);
  }
}


