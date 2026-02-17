// lib/repository/enrollment_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _enrollmentsCollection = 'enrollments';

  String _docId(String uid, String courseId) => '${uid}_$courseId';

  Future<bool> isEnrolled({required String uid, required String courseId}) async {
    final doc = await _firestore.collection(_enrollmentsCollection).doc(_docId(uid, courseId)).get();
    return doc.exists && (doc.data()?['status'] == 'active');
  }

  Stream<bool> watchEnrollment({required String uid, required String courseId}) {
    return _firestore
        .collection(_enrollmentsCollection)
        .doc(_docId(uid, courseId))
        .snapshots()
        .map((snap) => snap.exists && (snap.data()?['status'] == 'active'));
  }

  Future<void> enroll({required String uid, required String courseId}) async {
    await _firestore.collection(_enrollmentsCollection).doc(_docId(uid, courseId)).set({
      'uid': uid,
      'courseId': courseId,
      'status': 'active',
      'enrolledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unenroll({required String uid, required String courseId}) async {
    await _firestore.collection(_enrollmentsCollection).doc(_docId(uid, courseId)).set({
      'uid': uid,
      'courseId': courseId,
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<String>> getUserCourseIds({required String uid}) async {
    final snapshot = await _firestore
        .collection(_enrollmentsCollection)
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs.map((d) => d.data()['courseId'] as String).toList();
  }
}


