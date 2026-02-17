// lib/repository/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/chat_message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _messagesCollection = 'chat_messages';
  final String _sessionsCollection = 'chat_sessions';

  // Send a message
  Future<void> sendMessage({
    required String userId,
    required String role,
    required String content,
    String? sessionId,
    String? courseId,
    String? lessonId,
  }) async {
    try {
      final now = DateTime.now();
      final messageId = _firestore.collection(_messagesCollection).doc().id;
      final currentSessionId = sessionId ?? _generateSessionId(userId, now);

      // Save message
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .set({
        'messageId': messageId,
        'userId': userId,
        'sessionId': currentSessionId,
        'role': role,
        'content': content,
        'timestamp': Timestamp.fromDate(now),
        'courseId': courseId,
        'lessonId': lessonId,
      });

      // Update or create session
      if (sessionId == null) {
        await _firestore
            .collection(_sessionsCollection)
            .doc(currentSessionId)
            .set({
          'sessionId': currentSessionId,
          'userId': userId,
          'title': content.length > 50 ? content.substring(0, 50) : content,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        await _firestore
            .collection(_sessionsCollection)
            .doc(sessionId)
            .update({
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a session
  Future<List<ChatMessageModel>> getSessionMessages(String sessionId) async {
    try {
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap({
          'messageId': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  // Watch messages for a session (real-time)
  Stream<List<ChatMessageModel>> watchSessionMessages(String sessionId) {
    return _firestore
        .collection(_messagesCollection)
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap({
          'messageId': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // Get all chat sessions for a user
  Future<List<ChatSessionModel>> getUserSessions(String userId) async {
    try {
      // Try with orderBy first (requires index)
      try {
        final snapshot = await _firestore
            .collection(_sessionsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('updatedAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          return ChatSessionModel.fromMap({
            'sessionId': doc.id,
            ...doc.data(),
          });
        }).toList();
      } catch (indexError) {
        // If index is not ready, fallback to query without orderBy
        // Then sort client-side
        print('Index query failed, using fallback: $indexError');
        final snapshot = await _firestore
            .collection(_sessionsCollection)
            .where('userId', isEqualTo: userId)
            .get();

        final sessions = snapshot.docs.map((doc) {
          return ChatSessionModel.fromMap({
            'sessionId': doc.id,
            ...doc.data(),
          });
        }).toList();

        // Sort by updatedAt descending client-side
        sessions.sort((a, b) {
          // Handle null values: null values go to the end
          if (a.updatedAt == null && b.updatedAt == null) return 0;
          if (a.updatedAt == null) return 1;
          if (b.updatedAt == null) return -1;
          return b.updatedAt!.compareTo(a.updatedAt!);
        });

        return sessions;
      }
    } catch (e) {
      throw Exception('Failed to get sessions: $e');
    }
  }

  // Get or create current session
  Future<String> getOrCreateCurrentSession(String userId) async {
    try {
      // Try to get the most recent session
      // If index is not ready, this will fail, so we catch and create new session
      try {
        final snapshot = await _firestore
            .collection(_sessionsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('updatedAt', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final docData = snapshot.docs.first.data();
          final updatedAt = docData['updatedAt'];
          
          if (updatedAt != null) {
            final lastUpdate = (updatedAt as Timestamp).toDate();
            final now = DateTime.now();
            final difference = now.difference(lastUpdate);

            // If last session was less than 1 hour ago, reuse it
            if (difference.inHours < 1) {
              return snapshot.docs.first.id;
            }
          }
        }
      } catch (indexError) {
        // Index might not be ready yet, or query failed
        // Fall through to create a new session
        print('Index query failed (index may not be ready): $indexError');
      }

      // Create new session (either no existing session or index not ready)
      final sessionId = _generateSessionId(userId, DateTime.now());
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .set({
        'sessionId': sessionId,
        'userId': userId,
        'title': 'New Conversation',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return sessionId;
    } catch (e) {
      throw Exception('Failed to get or create session: $e');
    }
  }

  // Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      // Delete all messages in the session
      final messagesSnapshot = await _firestore
          .collection(_messagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete session
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // Clear all messages for a session (keep session)
  Future<void> clearSessionMessages(String sessionId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection(_messagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear messages: $e');
    }
  }

  // Helper to generate session ID
  String _generateSessionId(String userId, DateTime timestamp) {
    return '${userId}_${timestamp.millisecondsSinceEpoch}';
  }
}

