// lib/repository/progress_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/video_progress_model.dart';

class ProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _progressCollection = 'video_progress';

  // Get or create progress for a video
  Future<VideoProgressModel?> getVideoProgress({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final progressId = _generateProgressId(userId, courseId, moduleId, lessonId);
      final doc = await _firestore
          .collection(_progressCollection)
          .doc(progressId)
          .get();

      if (doc.exists) {
        return VideoProgressModel.fromMap({
          'progressId': progressId,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get video progress: $e');
    }
  }

  // Save or update video progress
  Future<void> saveVideoProgress({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String videoURL,
    required int currentPosition,
    required int totalDuration,
    bool isCompleted = false,
  }) async {
    try {
      final progressId = _generateProgressId(userId, courseId, moduleId, lessonId);
      final now = DateTime.now();

      final doc = await _firestore
          .collection(_progressCollection)
          .doc(progressId)
          .get();

      if (doc.exists) {
        // Update existing progress
        await _firestore
            .collection(_progressCollection)
            .doc(progressId)
            .update({
          'currentPosition': currentPosition,
          'totalDuration': totalDuration,
          'isCompleted': isCompleted,
          'lastWatchedAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        // Create new progress
        await _firestore
            .collection(_progressCollection)
            .doc(progressId)
            .set({
          'progressId': progressId,
          'userId': userId,
          'courseId': courseId,
          'moduleId': moduleId,
          'lessonId': lessonId,
          'videoURL': videoURL,
          'currentPosition': currentPosition,
          'totalDuration': totalDuration,
          'isCompleted': isCompleted,
          'lastWatchedAt': Timestamp.fromDate(now),
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      throw Exception('Failed to save video progress: $e');
    }
  }

  // Mark video as completed
  Future<void> markVideoCompleted({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final progressId = _generateProgressId(userId, courseId, moduleId, lessonId);
      await _firestore
          .collection(_progressCollection)
          .doc(progressId)
          .update({
        'isCompleted': true,
        'lastWatchedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mark video as completed: $e');
    }
  }

  // Get all progress for a course
  Future<List<VideoProgressModel>> getCourseProgress({
    required String userId,
    required String courseId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_progressCollection)
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .get();

      return snapshot.docs.map((doc) {
        return VideoProgressModel.fromMap({
          'progressId': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get course progress: $e');
    }
  }

  // Get overall course completion percentage
  Future<double> getCourseCompletionPercentage({
    required String userId,
    required String courseId,
    required int totalLessons,
  }) async {
    try {
      if (totalLessons == 0) return 0.0;

      final snapshot = await _firestore
          .collection(_progressCollection)
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .where('isCompleted', isEqualTo: true)
          .get();

      final completedCount = snapshot.docs.length;
      return (completedCount / totalLessons * 100).clamp(0.0, 100.0);
    } catch (e) {
      throw Exception('Failed to get course completion: $e');
    }
  }

  // Watch progress for a specific video (real-time updates)
  Stream<VideoProgressModel?> watchVideoProgress({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) {
    final progressId = _generateProgressId(userId, courseId, moduleId, lessonId);
    return _firestore
        .collection(_progressCollection)
        .doc(progressId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return VideoProgressModel.fromMap({
        'progressId': progressId,
        ...doc.data()!,
      });
    });
  }

  // Helper to generate progress ID
  String _generateProgressId(
    String userId,
    String courseId,
    String moduleId,
    String lessonId,
  ) {
    return '$userId-$courseId-$moduleId-$lessonId';
  }
}

