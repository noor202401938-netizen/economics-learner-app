// lib/repository/payment_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _paymentsCollection = 'payments'; // one doc per uid_courseId

  String _paymentDocId(String uid, String courseId) => '${uid}_$courseId';

  // Check if user has paid for a specific course
  Future<bool> hasUserPaidForCourse({required String uid, required String courseId}) async {
    final doc = await _firestore.collection(_paymentsCollection).doc(_paymentDocId(uid, courseId)).get();
    return doc.exists && (doc.data()?['status'] == 'paid');
  }

  Stream<bool> watchUserPaidForCourse({required String uid, required String courseId}) {
    return _firestore
        .collection(_paymentsCollection)
        .doc(_paymentDocId(uid, courseId))
        .snapshots()
        .map((snap) => snap.exists && (snap.data()?['status'] == 'paid'));
  }

  Future<void> createPendingPayment({
    required String uid,
    required String courseId,
    required int amountCents,
    String currency = 'USD',
  }) async {
    await _firestore.collection(_paymentsCollection).doc(_paymentDocId(uid, courseId)).set({
      'uid': uid,
      'courseId': courseId,
      'status': 'pending',
      'amountCents': amountCents,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markPaidForCourse({required String uid, required String courseId}) async {
    await _firestore.collection(_paymentsCollection).doc(_paymentDocId(uid, courseId)).set({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Legacy method for backward compatibility (if needed elsewhere)
  // Keep for now but deprecated - use hasUserPaidForCourse instead
  @deprecated
  Future<bool> hasUserPaid({required String uid}) async {
    // This is no longer used - return false as there's no global platform fee
    return false;
  }
}


