// lib/screens/student/student_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../business_logic/auth_manager.dart';
import '../../repository/auth_repository.dart';
import '../../backend/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_courses_screen.dart';
import 'ai_tutor_chat_screen.dart';
import '../notifications_panel.dart';
import 'certificates_list_screen.dart';
import '../theme_accessibility_screen.dart';
import '../../business_logic/recommendation_engine.dart';
import '../../model/course_model.dart';
import 'course_list_screen.dart';
import 'course_content_screen.dart';
import '../../repository/enrollment_repository.dart';
import '../../repository/course_repository.dart';
import '../../repository/progress_repository.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final AuthManager _authManager = AuthManager();
  final AuthRepository _authRepository = AuthRepository();
  final FirestoreService _firestoreService = FirestoreService();
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  final CourseRepository _courseRepository = CourseRepository();
  final ProgressRepository _progressRepository = ProgressRepository();
  int _selectedIndex = 0;
  Map<String, dynamic>? _userProfile;
  List<CourseModel> _recommendedCourses = [];
  List<CourseModel> _enrolledCourses = [];
  bool _loadingEnrolled = false;
  bool _isLoadingRecommendations = false;
  int _completedCourseCount = 0;
  int _totalLearningHours = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadEnrolledCourses();
    _loadRecommendations();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final ids = await _enrollmentRepository.getUserCourseIds(uid: user.uid);
      int completed = 0;
      int totalHours = 0;
      for (final courseId in ids) {
        final course = await _courseRepository.getCourseById(courseId);
        if (course != null) {
          totalHours += course.duration;
          final totalLessons = course.syllabus.fold<int>(
            0,
            (sum, module) => sum + module.lessons.length,
          );
          if (totalLessons > 0) {
            final pct = await _progressRepository.getCourseCompletionPercentage(
              userId: user.uid,
              courseId: courseId,
              totalLessons: totalLessons,
            );
            if (pct >= 100) completed++;
          }
        }
      }
      if (mounted) {
        setState(() {
          _completedCourseCount = completed;
          _totalLearningHours = totalHours;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() => _loadingEnrolled = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _enrolledCourses = [];
          _loadingEnrolled = false;
        });
        return;
      }
      final ids = await _enrollmentRepository.getUserCourseIds(uid: user.uid);
      final List<CourseModel> result = [];
      for (final id in ids) {
        final course = await _courseRepository.getCourseById(id);
        if (course != null) result.add(course);
      }
      setState(() {
        _enrolledCourses = result;
        _loadingEnrolled = false;
      });
    } catch (e) {
      setState(() => _loadingEnrolled = false);
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final recommendations = await _recommendationEngine.getRecommendations();
      setState(() {
        _recommendedCourses = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() => _isLoadingRecommendations = false);
    }
  }

  Future<void> _loadUserProfile() async {
    final user = _authRepository.getCurrentUser();
    if (user != null) {
      final profile = await _authRepository.getUserProfile(user.uid);
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Widget _buildGreetingName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text(
        'Student',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        String name = _userProfile?['displayName'] ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'Student';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null &&
              (data['displayName'] as String?) != null &&
              (data['displayName'] as String).isNotEmpty) {
            name = data['displayName'];
          }
        }
        return Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildCoursesScreen();
      case 2:
        return _buildProgressScreen();
      case 3:
        return _buildProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Tutor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPanel(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4169E1),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4169E1),
                  Color(0xFF1E3A8A),
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                _buildGreetingName(),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickStat(
                          'Courses',
                          '${_enrolledCourses.length}',
                          Icons.book,
                          Colors.blue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Completed',
                          '$_completedCourseCount',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          'Hours',
                          '$_totalLearningHours',
                          Icons.access_time,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // AI Tutor Chat Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AITutorChatScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4169E1),
                      Color(0xFF1E3A8A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Tutor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get instant help with your questions',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recommended Courses Section
          if (_recommendedCourses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended for You',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedIndex = 1);
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _recommendedCourses.length,
                itemBuilder: (context, index) {
                  final course = _recommendedCourses[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseContentScreen(
                                courseId: course.courseId,
                                title: course.title,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: course.thumbnailURL.isNotEmpty
                                    ? Image.network(
                                        course.thumbnailURL,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.school,
                                        size: 40,
                                        color: Color(0xFF4169E1),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 14, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          course.rating.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Spacer(),
                                      Flexible(
                                        child: Text(
                                          course.price == 0
                                              ? 'FREE'
                                              : '\$${course.price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: course.price == 0
                                                ? Colors.green
                                                : const Color(0xFF4169E1),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Continue Learning Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue Learning',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Show enrolled courses if available
                _loadingEnrolled
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF4169E1)))
                    : _enrolledCourses.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.auto_stories_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No courses in progress',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start learning by enrolling in a course',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF4169E1),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() => _selectedIndex = 1);
                                      },
                                      child: const Text('Browse Courses'),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 2),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MyCoursesScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text('My Courses'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _enrolledCourses.length,
                              itemBuilder: (context, index) {
                                final course = _enrolledCourses[index];
                                return Container(
                                  width: 300,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: Card(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CourseContentScreen(
                                              courseId: course.courseId,
                                              title: course.title,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                              ),
                                              child: course
                                                      .thumbnailURL.isNotEmpty
                                                  ? Image.network(
                                                      course.thumbnailURL,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : const Icon(
                                                      Icons.school,
                                                      size: 40,
                                                      color: Color(0xFF4169E1),
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  course.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star,
                                                        size: 14,
                                                        color: Colors.amber),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        course.rating
                                                            .toStringAsFixed(1),
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Flexible(
                                                      child: Text(
                                                        course.price == 0
                                                            ? 'FREE'
                                                            : '\$${course.price.toStringAsFixed(0)}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: course.price ==
                                                                  0
                                                              ? Colors.green
                                                              : const Color(
                                                                  0xFF4169E1),
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesScreen() {
    return const CourseListScreen();
  }

  Widget _buildProgressScreen() {
    if (_loadingEnrolled) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4169E1)),
      );
    }

    if (_enrolledCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 100,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'No progress data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enroll in a course to start tracking your progress',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4169E1), Color(0xFF1E3A8A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learning Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Enrolled', '${_enrolledCourses.length}'),
                    _buildSummaryItem('Completed', '$_completedCourseCount'),
                    _buildSummaryItem('Hours', '$_totalLearningHours'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Course Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Per-course progress cards
          ...(_enrolledCourses.map((course) {
            final totalLessons = course.syllabus.fold<int>(
              0,
              (sum, module) => sum + module.lessons.length,
            );
            return FutureBuilder<double>(
              future: user != null && totalLessons > 0
                  ? _progressRepository.getCourseCompletionPercentage(
                      userId: user.uid,
                      courseId: course.courseId,
                      totalLessons: totalLessons,
                    )
                  : Future.value(0.0),
              builder: (context, snapshot) {
                final pct = snapshot.data ?? 0.0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseContentScreen(course: course),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalLessons lessons · ${course.duration}h',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct >= 100
                                    ? Colors.green
                                    : const Color(0xFF4169E1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${pct.toStringAsFixed(0)}% complete',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: pct >= 100
                                      ? Colors.green
                                      : const Color(0xFF4169E1),
                                ),
                              ),
                              if (pct >= 100)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          })),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileScreen() {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.streamUserProfile(user?.uid ?? ''),
            builder: (context, snapshot) {
              String displayName = user?.displayName ?? 'Student';
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null &&
                    (data['displayName'] as String?) != null &&
                    (data['displayName'] as String).isNotEmpty) {
                  displayName = data['displayName'];
                }
              } else if (_userProfile != null &&
                  (_userProfile!['displayName'] as String?) != null &&
                  (_userProfile!['displayName'] as String).isNotEmpty) {
                displayName = _userProfile!['displayName'];
              }

              return Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        const Color(0xFF4169E1).withValues(alpha: 0.1),
                    child: Text(
                      (displayName.isNotEmpty
                              ? displayName
                              : user?.email ?? 'U')[0]
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4169E1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileOption(
            'Edit Profile',
            Icons.edit,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              if (result == true) {
                // Profile was updated, reload it
                _loadUserProfile();
              }
            },
          ),
          _buildProfileOption(
            'Change Password',
            Icons.lock_outline,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          _buildProfileOption(
            'Notifications',
            Icons.notifications_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPanel(),
                ),
              );
            },
          ),
          _buildProfileOption(
            'Certificates',
            Icons.workspace_premium,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CertificatesListScreen(),
                ),
              );
            },
          ),
          _buildProfileOption(
            'Theme & Accessibility',
            Icons.palette,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeAccessibilityScreen(),
                ),
              );
            },
          ),
          _buildProfileOption(
            'Help & Support',
            Icons.help_outline,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          _buildProfileOption(
            'About',
            Icons.info_outline,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                await _authManager.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4169E1)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
