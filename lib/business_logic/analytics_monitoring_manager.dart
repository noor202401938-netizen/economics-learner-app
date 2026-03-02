// lib/business_logic/analytics_monitoring_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repository/progress_repository.dart';
import '../repository/enrollment_repository.dart';
import '../repository/quiz_repository.dart';

class AnalyticsMonitoringManager {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProgressRepository _progressRepository = ProgressRepository();
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  final QuizRepository _quizRepository = QuizRepository();

  // Log event
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters != null 
          ? parameters.map((key, value) => MapEntry(key, value as Object))
          : null,
    );
  }

  // Log screen view
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Get course completion statistics
  Future<Map<String, dynamic>> getCourseStats(String courseId) async {
    try {
      final enrollments = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: 'active')
          .get();
      final totalEnrollments = enrollments.docs.length;

      int completedCount = 0;
      double totalScore = 0;
      int scoreCount = 0;

      for (final doc in enrollments.docs) {
        final uid = doc.data()['uid'] as String?;
        if (uid == null) continue;
        final pct = await _progressRepository.getCourseCompletionPercentage(
          userId: uid,
          courseId: courseId,
          totalLessons: 10,
        );
        if (pct >= 100) completedCount++;

        final quizResults = await _quizRepository.getQuizResults(
          userId: uid,
          courseId: courseId,
        );
        for (final result in quizResults) {
          totalScore += result['score'] as num? ?? 0;
          scoreCount++;
        }
      }

      return {
        'totalEnrollments': totalEnrollments,
        'completionRate': totalEnrollments > 0
            ? (completedCount / totalEnrollments * 100)
            : 0.0,
        'averageScore': scoreCount > 0 ? (totalScore / scoreCount) : 0.0,
      };
    } catch (e) {
      return {
        'totalEnrollments': 0,
        'completionRate': 0.0,
        'averageScore': 0.0,
      };
    }
  }

  // Get user learning statistics
  Future<Map<String, dynamic>> getUserLearningStats(String userId) async {
    try {
      final enrolledCourses = await _enrollmentRepository.getUserCourseIds(
        uid: userId,
      );

      int completedCourses = 0;
      int totalLessonsWatched = 0;

      for (final courseId in enrolledCourses) {
        final progress = await _progressRepository.getCourseProgress(
          userId: userId,
          courseId: courseId,
        );
        totalLessonsWatched += progress.where((p) => p.isCompleted).length;

        final completion = await _progressRepository.getCourseCompletionPercentage(
          userId: userId,
          courseId: courseId,
          totalLessons: progress.length > 0 ? progress.length : 1,
        );
        if (completion >= 100) completedCourses++;
      }

      final quizSubmissions = await _quizRepository.getUserQuizSubmissions(userId);

      return {
        'enrolledCourses': enrolledCourses.length,
        'completedCourses': completedCourses,
        'totalLessonsWatched': totalLessonsWatched,
        'totalQuizzesTaken': quizSubmissions.length,
      };
    } catch (e) {
      return {};
    }
  }

  // Track course enrollment
  Future<void> trackEnrollment(String courseId) async {
    await logEvent('course_enrolled', {'course_id': courseId});
  }

  // Track course completion
  Future<void> trackCourseCompletion(String courseId) async {
    await logEvent('course_completed', {'course_id': courseId});
  }

  // Track quiz completion
  Future<void> trackQuizCompletion(String quizId, int score) async {
    await logEvent('quiz_completed', {
      'quiz_id': quizId,
      'score': score,
    });
  }
}

