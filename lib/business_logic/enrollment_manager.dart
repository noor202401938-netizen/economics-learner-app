// lib/business_logic/enrollment_manager.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../repository/enrollment_repository.dart';
import '../repository/course_repository.dart';

class EnrollmentManager {
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  final CourseRepository _courseRepository = CourseRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  Future<String?> enrollInCourse(String courseId) async {
    final user = _user;
    if (user == null) return 'Not authenticated';
    try {
      final already = await _enrollmentRepository.isEnrolled(uid: user.uid, courseId: courseId);
      if (already) return null; // No-op
      await _enrollmentRepository.enroll(uid: user.uid, courseId: courseId);
      await _courseRepository.incrementEnrollment(courseId);
      return null;
    } catch (e) {
      return 'Failed to enroll: ${e.toString()}';
    }
  }

  Future<String?> unenrollFromCourse(String courseId) async {
    final user = _user;
    if (user == null) return 'Not authenticated';
    try {
      await _enrollmentRepository.unenroll(uid: user.uid, courseId: courseId);
      // Optional: decrement count; keep simple and avoid negative under concurrency
      return null;
    } catch (e) {
      return 'Failed to unenroll: ${e.toString()}';
    }
  }

  Future<bool> isEnrolled(String courseId) async {
    final user = _user;
    if (user == null) return false;
    return _enrollmentRepository.isEnrolled(uid: user.uid, courseId: courseId);
  }

  Stream<bool> watchEnrollment(String courseId) {
    final user = _user;
    if (user == null) {
      return Stream<bool>.value(false);
    }
    return _enrollmentRepository.watchEnrollment(uid: user.uid, courseId: courseId);
  }
}


