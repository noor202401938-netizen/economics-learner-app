// lib/backend/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user profile after registration
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    String role = 'student', // default role is student
    String? phone,
    String? grade,
    String? interest,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName ?? '',
        'photoURL': photoURL ?? '',
        'role': role,
        // Optional onboarding fields
        'phone': phone ?? '',
        'grade': grade ?? '',
        'interest': interest ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      print("Error creating user profile: $e");
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Error getting user profile: $e");
      return null;
    }
  }

  // Update last login time
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating last login: $e");
    }
  }

  // Get user role
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        return data?['role'] ?? 'student';
      }
      return 'student';
    } catch (e) {
      print("Error getting user role: $e");
      return 'student';
    }
  }

  // Update user role (Admin only)
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating user role: $e");
      rethrow;
    }
  }

  // Get all users (Admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error getting all users: $e");
      return [];
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoURL,
    String? phone,
    String? grade,
    String? interest,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (phone != null) updates['phone'] = phone;
      if (grade != null) updates['grade'] = grade;
      if (interest != null) updates['interest'] = interest;

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print("Error updating user profile: $e");
      rethrow;
    }
  }

  // Delete user profile (Admin only)
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print("Error deleting user profile: $e");
      rethrow;
    }
  }

  // Stream user profile changes
  Stream<DocumentSnapshot> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print("Error checking user existence: $e");
      return false;
    }
  }
}