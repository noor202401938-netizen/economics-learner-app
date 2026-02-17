// lib/backend/storage_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file to Firebase Storage
  Future<String> uploadFile({
    required String path,
    required Uint8List fileData,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(
        fileData,
        SettableMetadata(contentType: contentType),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload certificate PDF
  Future<String> uploadCertificate({
    required String userId,
    required String courseId,
    required Uint8List pdfData,
  }) async {
    final path = 'certificates/$userId/${courseId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    return await uploadFile(
      path: path,
      fileData: pdfData,
      contentType: 'application/pdf',
    );
  }

  // Upload assignment file
  Future<String> uploadAssignmentFile({
    required String userId,
    required String assignmentId,
    required Uint8List fileData,
    required String fileName,
  }) async {
    final path = 'assignments/$userId/$assignmentId/$fileName';
    return await uploadFile(
      path: path,
      fileData: fileData,
    );
  }

  // Delete file
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Get download URL
  Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
}

