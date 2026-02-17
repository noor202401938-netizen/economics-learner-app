// lib/repository/quiz_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/quiz_model.dart';

class QuizRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _quizzesCollection = 'quizzes';
  final String _quizSubmissionsCollection = 'quiz_submissions';
  final String _assignmentsCollection = 'assignments';
  final String _assignmentSubmissionsCollection = 'assignment_submissions';

  // Quiz Methods

  // Get quiz by lesson ID
  Future<QuizModel?> getQuizByLessonId(String lessonId) async {
    try {
      final snapshot = await _firestore
          .collection(_quizzesCollection)
          .where('lessonId', isEqualTo: lessonId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return QuizModel.fromMap({
          'quizId': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get quiz: $e');
    }
  }

  // Save quiz
  Future<void> saveQuiz(QuizModel quiz) async {
    try {
      await _firestore
          .collection(_quizzesCollection)
          .doc(quiz.quizId)
          .set(quiz.toMap());
    } catch (e) {
      throw Exception('Failed to save quiz: $e');
    }
  }

  // Submit quiz
  Future<void> submitQuiz(QuizSubmissionModel submission) async {
    try {
      await _firestore
          .collection(_quizSubmissionsCollection)
          .doc(submission.submissionId)
          .set(submission.toMap());
    } catch (e) {
      throw Exception('Failed to submit quiz: $e');
    }
  }

  // Get user's quiz submission
  Future<QuizSubmissionModel?> getUserQuizSubmission({
    required String userId,
    required String quizId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_quizSubmissionsCollection)
          .where('userId', isEqualTo: userId)
          .where('quizId', isEqualTo: quizId)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return QuizSubmissionModel.fromMap({
          'submissionId': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get quiz submission: $e');
    }
  }

  // Get all quiz submissions for a user
  Future<List<QuizSubmissionModel>> getUserQuizSubmissions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_quizSubmissionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return QuizSubmissionModel.fromMap({
          'submissionId': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get quiz submissions: $e');
    }
  }

  // Assignment Methods

  // Get assignment by lesson ID
  Future<AssignmentModel?> getAssignmentByLessonId(String lessonId) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentsCollection)
          .where('lessonId', isEqualTo: lessonId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AssignmentModel.fromMap({
          'assignmentId': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get assignment: $e');
    }
  }

  // Save assignment
  Future<void> saveAssignment(AssignmentModel assignment) async {
    try {
      await _firestore
          .collection(_assignmentsCollection)
          .doc(assignment.assignmentId)
          .set(assignment.toMap());
    } catch (e) {
      throw Exception('Failed to save assignment: $e');
    }
  }

  // Submit assignment
  Future<void> submitAssignment(AssignmentSubmissionModel submission) async {
    try {
      await _firestore
          .collection(_assignmentSubmissionsCollection)
          .doc(submission.submissionId)
          .set(submission.toMap());
    } catch (e) {
      throw Exception('Failed to submit assignment: $e');
    }
  }

  // Get user's assignment submission
  Future<AssignmentSubmissionModel?> getUserAssignmentSubmission({
    required String userId,
    required String assignmentId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentSubmissionsCollection)
          .where('userId', isEqualTo: userId)
          .where('assignmentId', isEqualTo: assignmentId)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AssignmentSubmissionModel.fromMap({
          'submissionId': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get assignment submission: $e');
    }
  }

  // Get all assignment submissions for a user
  Future<List<AssignmentSubmissionModel>> getUserAssignmentSubmissions(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentSubmissionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return AssignmentSubmissionModel.fromMap({
          'submissionId': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get assignment submissions: $e');
    }
  }
}

