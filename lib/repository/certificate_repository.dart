// lib/repository/certificate_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/certificate_model.dart';

class CertificateRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _certificatesCollection = 'certificates';

  // Generate certificate ID
  String _generateCertificateId(String userId, String courseId, String lessonId) {
    return '${userId}_${courseId}_${lessonId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Create a certificate
  Future<CertificateModel> createCertificate({
    required String userId,
    required String userName,
    required String courseId,
    required String courseName,
    required String lessonId,
    required String lessonName,
  }) async {
    try {
      final completionDate = DateTime.now();
      final dayOfWeek = CertificateModel.getDayOfWeek(completionDate);
      final certificateId = _generateCertificateId(userId, courseId, lessonId);

      final certificate = CertificateModel(
        certificateId: certificateId,
        userId: userId,
        userName: userName,
        courseId: courseId,
        courseName: courseName,
        lessonId: lessonId,
        lessonName: lessonName,
        completionDate: completionDate,
        dayOfWeek: dayOfWeek,
      );

      // Save to Firestore
      await _firestore
          .collection(_certificatesCollection)
          .doc(certificateId)
          .set(certificate.toMap());

      return certificate;
    } catch (e) {
      throw Exception('Failed to create certificate: $e');
    }
  }

  // Get certificate by ID
  Future<CertificateModel?> getCertificate(String certificateId) async {
    try {
      final doc = await _firestore
          .collection(_certificatesCollection)
          .doc(certificateId)
          .get();

      if (doc.exists) {
        return CertificateModel.fromMap({
          'certificateId': certificateId,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get certificate: $e');
    }
  }

  // Get all certificates for a user
  Future<List<CertificateModel>> getUserCertificates(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_certificatesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('completionDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return CertificateModel.fromMap({
          'certificateId': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      // If index is not ready, fallback to query without orderBy
      try {
        final snapshot = await _firestore
            .collection(_certificatesCollection)
            .where('userId', isEqualTo: userId)
            .get();

        final certificates = snapshot.docs.map((doc) {
          return CertificateModel.fromMap({
            'certificateId': doc.id,
            ...doc.data(),
          });
        }).toList();

        // Sort by completionDate descending client-side
        certificates.sort((a, b) {
          return b.completionDate.compareTo(a.completionDate);
        });

        return certificates;
      } catch (fallbackError) {
        throw Exception('Failed to get user certificates: $e');
      }
    }
  }

  // Check if certificate already exists for a lesson
  Future<bool> certificateExists({
    required String userId,
    required String courseId,
    required String lessonId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_certificatesCollection)
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .where('lessonId', isEqualTo: lessonId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // If index is not ready, try without where clauses
      try {
        final snapshot = await _firestore
            .collection(_certificatesCollection)
            .where('userId', isEqualTo: userId)
            .get();

        return snapshot.docs.any((doc) {
          final data = doc.data();
          return data['courseId'] == courseId && data['lessonId'] == lessonId;
        });
      } catch (fallbackError) {
        return false; // Assume doesn't exist if query fails
      }
    }
  }
}
