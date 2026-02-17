// lib/repository/course_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/course_model.dart';

class CourseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coursesCollection = 'courses';

  // Create a new course
  Future<void> createCourse(CourseModel course) async {
    try {
      await _firestore
          .collection(_coursesCollection)
          .doc(course.courseId)
          .set(course.toMap());
    } catch (e) {
      print('Error creating course: $e');
      rethrow;
    }
  }

  // Get all published courses
  Future<List<CourseModel>> getAllPublishedCourses() async {
    try {
      // First get all published courses
      QuerySnapshot snapshot = await _firestore
          .collection(_coursesCollection)
          .where('isPublished', isEqualTo: true)
          .get();

      // Convert to CourseModel list
      List<CourseModel> courses = snapshot.docs
          .map((doc) {
            try {
              return CourseModel.fromMap(doc.data() as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing course ${doc.id}: $e');
              return null;
            }
          })
          .where((course) => course != null)
          .cast<CourseModel>()
          .toList();

      // Sort by createdAt descending (client-side sorting to avoid index requirement)
      courses.sort((a, b) {
        try {
          final aCreated = a.createdAt;
          final bCreated = b.createdAt;
          return bCreated.compareTo(aCreated);
        } catch (e) {
          return 0; // If sorting fails, maintain original order
        }
      });

      return courses;
    } catch (e) {
      print('Error getting published courses: $e');
      // If query fails, try without where clause as fallback
      try {
        QuerySnapshot snapshot = await _firestore
            .collection(_coursesCollection)
            .get();
        
        List<CourseModel> courses = snapshot.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                if (data['isPublished'] == true) {
                  return CourseModel.fromMap(data);
                }
                return null;
              } catch (e) {
                print('Error parsing course ${doc.id}: $e');
                return null;
              }
            })
            .where((course) => course != null)
            .cast<CourseModel>()
            .toList();

        courses.sort((a, b) {
          try {
            final aCreated = a.createdAt;
            final bCreated = b.createdAt;
            return bCreated.compareTo(aCreated);
          } catch (e) {
            return 0; // If sorting fails, maintain original order
          }
        });

        return courses;
      } catch (e2) {
        print('Fallback query also failed: $e2');
        return [];
      }
    }
  }

  // Get all courses (for admin)
  Future<List<CourseModel>> getAllCourses() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_coursesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CourseModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all courses: $e');
      return [];
    }
  }

  // Get course by ID
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_coursesCollection)
          .doc(courseId)
          .get();

      if (doc.exists) {
        return CourseModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting course: $e');
      return null;
    }
  }

  // Update course
  Future<void> updateCourse(CourseModel course) async {
    try {
      await _firestore
          .collection(_coursesCollection)
          .doc(course.courseId)
          .update(course.toMap());
    } catch (e) {
      print('Error updating course: $e');
      rethrow;
    }
  }

  // Delete course
  Future<void> deleteCourse(String courseId) async {
    try {
      await _firestore
          .collection(_coursesCollection)
          .doc(courseId)
          .delete();
    } catch (e) {
      print('Error deleting course: $e');
      rethrow;
    }
  }

  // Search courses
  Future<List<CourseModel>> searchCourses(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_coursesCollection)
          .where('isPublished', isEqualTo: true)
          .get();

      // Filter locally (Firestore doesn't support full-text search natively)
      return snapshot.docs
          .map((doc) => CourseModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((course) =>
      course.title.toLowerCase().contains(query.toLowerCase()) ||
          course.description.toLowerCase().contains(query.toLowerCase()) ||
          course.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      print('Error searching courses: $e');
      return [];
    }
  }

  // Filter courses by category
  Future<List<CourseModel>> getCoursesByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_coursesCollection)
          .where('isPublished', isEqualTo: true)
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => CourseModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting courses by category: $e');
      return [];
    }
  }

  // Filter courses by level
  Future<List<CourseModel>> getCoursesByLevel(String level) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_coursesCollection)
          .where('isPublished', isEqualTo: true)
          .where('level', isEqualTo: level)
          .get();

      return snapshot.docs
          .map((doc) => CourseModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting courses by level: $e');
      return [];
    }
  }

  // Increment enrollment count
  Future<void> incrementEnrollment(String courseId) async {
    try {
      await _firestore
          .collection(_coursesCollection)
          .doc(courseId)
          .update({
        'enrollmentCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing enrollment: $e');
      rethrow;
    }
  }

  // Update course rating
  Future<void> updateCourseRating(String courseId, double newRating) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_coursesCollection)
          .doc(courseId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double currentRating = (data['rating'] ?? 0).toDouble();
        int ratingCount = (data['ratingCount'] ?? 0);

        // Calculate new average rating
        double totalRating = (currentRating * ratingCount) + newRating;
        int newRatingCount = ratingCount + 1;
        double averageRating = totalRating / newRatingCount;

        await _firestore
            .collection(_coursesCollection)
            .doc(courseId)
            .update({
          'rating': averageRating,
          'ratingCount': newRatingCount,
        });
      }
    } catch (e) {
      print('Error updating rating: $e');
      rethrow;
    }
  }

  // Stream courses (real-time updates)
  Stream<List<CourseModel>> streamPublishedCourses() {
    return _firestore
        .collection(_coursesCollection)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<CourseModel> courses = snapshot.docs
              .map((doc) {
                try {
                  return CourseModel.fromMap(doc.data());
                } catch (e) {
                  print('Error parsing course ${doc.id}: $e');
                  return null;
                }
              })
              .where((course) => course != null)
              .cast<CourseModel>()
              .toList();
          
          // Sort by createdAt descending (client-side)
          courses.sort((a, b) {
            try {
              final aCreated = a.createdAt;
              final bCreated = b.createdAt;
              return bCreated.compareTo(aCreated);
            } catch (e) {
              return 0; // If sorting fails, maintain original order
            }
          });
          
          return courses;
        });
  }

  // Get course count
  Future<int> getCourseCount({bool? publishedOnly}) async {
    try {
      Query query = _firestore.collection(_coursesCollection);

      if (publishedOnly == true) {
        query = query.where('isPublished', isEqualTo: true);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting course count: $e');
      return 0;
    }
  }
}