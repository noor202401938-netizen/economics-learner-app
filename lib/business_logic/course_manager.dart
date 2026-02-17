// lib/business_logic/course_manager.dart
import '../repository/course_repository.dart';
import '../model/course_model.dart';

class CourseManager {
  final CourseRepository _courseRepository = CourseRepository();

  // Get all published courses
  Future<List<CourseModel>> getPublishedCourses() async {
    return await _courseRepository.getAllPublishedCourses();
  }

  // Get all courses (admin only)
  Future<List<CourseModel>> getAllCourses() async {
    return await _courseRepository.getAllCourses();
  }

  // Get course by ID
  Future<CourseModel?> getCourse(String courseId) async {
    return await _courseRepository.getCourseById(courseId);
  }

  // Create new course (admin only)
  Future<String?> createCourse(CourseModel course) async {
    try {
      // Validate course data
      if (course.title.isEmpty) {
        return 'Course title is required';
      }
      if (course.description.isEmpty) {
        return 'Course description is required';
      }
      if (course.instructor.isEmpty) {
        return 'Instructor name is required';
      }
      if (course.price < 0) {
        return 'Price cannot be negative';
      }

      await _courseRepository.createCourse(course);
      return null; // Success
    } catch (e) {
      return 'Failed to create course: ${e.toString()}';
    }
  }

  // Update course (admin only)
  Future<String?> updateCourse(CourseModel course) async {
    try {
      if (course.title.isEmpty) {
        return 'Course title is required';
      }

      await _courseRepository.updateCourse(course);
      return null; // Success
    } catch (e) {
      return 'Failed to update course: ${e.toString()}';
    }
  }

  // Delete course (admin only)
  Future<String?> deleteCourse(String courseId) async {
    try {
      await _courseRepository.deleteCourse(courseId);
      return null; // Success
    } catch (e) {
      return 'Failed to delete course: ${e.toString()}';
    }
  }

  // Search courses
  Future<List<CourseModel>> searchCourses(String query) async {
    if (query.isEmpty) {
      return await getPublishedCourses();
    }
    return await _courseRepository.searchCourses(query);
  }

  // Filter by category
  Future<List<CourseModel>> filterByCategory(String category) async {
    return await _courseRepository.getCoursesByCategory(category);
  }

  // Filter by level
  Future<List<CourseModel>> filterByLevel(String level) async {
    return await _courseRepository.getCoursesByLevel(level);
  }

  // Get available categories
  Future<List<String>> getCategories() async {
    final courses = await getPublishedCourses();
    final categories = courses.map((course) => course.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Enroll in course
  Future<String?> enrollInCourse(String courseId) async {
    try {
      await _courseRepository.incrementEnrollment(courseId);
      return null; // Success
    } catch (e) {
      return 'Failed to enroll: ${e.toString()}';
    }
  }

  // Rate course
  Future<String?> rateCourse(String courseId, double rating) async {
    try {
      if (rating < 0 || rating > 5) {
        return 'Rating must be between 0 and 5';
      }

      await _courseRepository.updateCourseRating(courseId, rating);
      return null; // Success
    } catch (e) {
      return 'Failed to rate course: ${e.toString()}';
    }
  }

  // Stream courses for real-time updates
  Stream<List<CourseModel>> watchPublishedCourses() {
    return _courseRepository.streamPublishedCourses();
  }

  // Get course statistics
  Future<Map<String, dynamic>> getCourseStats() async {
    final courses = await getPublishedCourses();

    int totalCourses = courses.length;
    int totalEnrollments = courses.fold(0, (sum, course) => sum + course.enrollmentCount);
    double averageRating = courses.isEmpty
        ? 0.0
        : courses.fold(0.0, (sum, course) => sum + course.rating) / courses.length;

    return {
      'totalCourses': totalCourses,
      'totalEnrollments': totalEnrollments,
      'averageRating': averageRating,
    };
  }

  // Get course count
  Future<int> getCourseCount({bool publishedOnly = true}) async {
    return await _courseRepository.getCourseCount(publishedOnly: publishedOnly);
  }
}