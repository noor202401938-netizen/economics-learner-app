// lib/screens/student/course_list_screen.dart
import 'package:flutter/material.dart';
import '../../business_logic/course_manager.dart';
import '../../business_logic/search_filter_engine.dart';
import '../../model/course_model.dart';
import '../../business_logic/enrollment_manager.dart';
import '../../business_logic/payment_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_screen.dart';
import 'course_content_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final CourseManager _courseManager = CourseManager();
  final SearchFilterEngine _searchFilterEngine = SearchFilterEngine();
  final EnrollmentManager _enrollmentManager = EnrollmentManager();
  final TextEditingController _searchController = TextEditingController();

  List<CourseModel> _allCourses = [];
  List<CourseModel> _filteredCourses = [];
  List<String> _categories = [];

  String? _selectedCategory;
  String? _selectedLevel;
  String? _selectedSortBy;
  double? _minRating;
  double? _maxPrice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final courses = await _courseManager.getPublishedCourses();
    setState(() {
      _allCourses = courses;
      _filteredCourses = courses;
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    final categories = await _searchFilterEngine.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _filterCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _searchFilterEngine.searchCourses(
        query: _searchController.text.isEmpty ? null : _searchController.text,
        category: _selectedCategory,
        level: _selectedLevel,
        minRating: _minRating,
        maxPrice: _maxPrice?.toInt(),
        sortBy: _selectedSortBy,
      );
      setState(() {
        _filteredCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedLevel = null;
      _selectedSortBy = null;
      _minRating = null;
      _maxPrice = null;
    });
    _filterCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4169E1)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterCourses();
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4169E1), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) => _filterCourses(),
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Filter
                  if (_categories.isNotEmpty) ...[
                    ChoiceChip(
                      label: Text(_selectedCategory ?? 'All Categories'),
                      selected: _selectedCategory != null,
                      onSelected: (selected) {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Category',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('All'),
                                      selected: _selectedCategory == null,
                                      onSelected: (selected) {
                                        setState(() => _selectedCategory = null);
                                        _filterCourses();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ..._categories.map((category) {
                                      return ChoiceChip(
                                        label: Text(category),
                                        selected: _selectedCategory == category,
                                        onSelected: (selected) {
                                          setState(() => _selectedCategory = category);
                                          _filterCourses();
                                          Navigator.pop(context);
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      selectedColor: const Color(0xFF4169E1),
                      labelStyle: TextStyle(
                        color: _selectedCategory != null ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Level Filter
                  ChoiceChip(
                    label: Text(_selectedLevel ?? 'All Levels'),
                    selected: _selectedLevel != null,
                    onSelected: (selected) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Level',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('All'),
                                    selected: _selectedLevel == null,
                                    onSelected: (selected) {
                                      setState(() => _selectedLevel = null);
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Beginner'),
                                    selected: _selectedLevel == 'beginner',
                                    onSelected: (selected) {
                                      setState(() => _selectedLevel = 'beginner');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Intermediate'),
                                    selected: _selectedLevel == 'intermediate',
                                    onSelected: (selected) {
                                      setState(() => _selectedLevel = 'intermediate');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Advanced'),
                                    selected: _selectedLevel == 'advanced',
                                    onSelected: (selected) {
                                      setState(() => _selectedLevel = 'advanced');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    selectedColor: const Color(0xFF4169E1),
                    labelStyle: TextStyle(
                      color: _selectedLevel != null ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sort Filter
                  ChoiceChip(
                    label: Text(_selectedSortBy ?? 'Sort'),
                    selected: _selectedSortBy != null,
                    onSelected: (selected) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sort By',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Default'),
                                    selected: _selectedSortBy == null,
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = null);
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Rating'),
                                    selected: _selectedSortBy == 'rating',
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = 'rating');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Price'),
                                    selected: _selectedSortBy == 'price',
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = 'price');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Newest'),
                                    selected: _selectedSortBy == 'newest',
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = 'newest');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Popular'),
                                    selected: _selectedSortBy == 'popular',
                                    onSelected: (selected) {
                                      setState(() => _selectedSortBy = 'popular');
                                      _filterCourses();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    selectedColor: const Color(0xFF4169E1),
                    labelStyle: TextStyle(
                      color: _selectedSortBy != null ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Advanced Filters
                  Flexible(
                    child: ActionChip(
                      label: const Text('More Filters'),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => _buildAdvancedFiltersSheet(),
                        );
                      },
                      avatar: const Icon(Icons.tune, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Clear Filters
                  if (_selectedCategory != null || _selectedLevel != null || _selectedSortBy != null || _minRating != null || _maxPrice != null || _searchController.text.isNotEmpty)
                    Flexible(
                      child: ActionChip(
                        label: const Text('Clear'),
                        onPressed: _clearFilters,
                        avatar: const Icon(Icons.clear, size: 18),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_filteredCourses.length} course${_filteredCourses.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Course List
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4169E1),
                ),
              )
                  : _filteredCourses.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No courses found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredCourses.length,
                itemBuilder: (context, index) {
                  return _buildCourseCard(_filteredCourses[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          // Check if user is enrolled, if so navigate to course content
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && mounted) {
            final isEnrolled = await _enrollmentManager.isEnrolled(course.courseId);
            if (isEnrolled && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseContentScreen(
                    courseId: course.courseId,
                    title: course.title,
                  ),
                ),
              );
            }
            // If not enrolled, let the enroll button handle enrollment
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: const Color(0xFF4169E1).withOpacity(0.1),
              ),
              child: course.thumbnailURL.isNotEmpty
                  ? ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  course.thumbnailURL,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.school,
                        size: 60,
                        color: Color(0xFF4169E1),
                      ),
                    );
                  },
                ),
              )
                  : const Center(
                child: Icon(
                  Icons.school,
                  size: 60,
                  color: Color(0xFF4169E1),
                ),
              ),
            ),

            // Course Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Level
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4169E1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF4169E1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.level.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Instructor
                  Text(
                    'by ${course.instructor}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    course.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Footer: Rating, Duration, Price
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' (${course.ratingCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.duration}h',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        course.price == 0
                            ? 'FREE'
                            : '\$${course.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: course.price == 0
                              ? Colors.green
                              : const Color(0xFF4169E1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEnrollButton(course),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollButton(CourseModel course) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4169E1),
            foregroundColor: Colors.white,
          ),
          child: const Text('Login to Enroll'),
        ),
      );
    }

    return StreamBuilder<bool>(
      stream: _enrollmentManager.watchEnrollment(course.courseId),
      builder: (context, snapshot) {
        final enrolled = snapshot.data == true;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enrolled
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseContentScreen(
                          courseId: course.courseId,
                          title: course.title,
                        ),
                      ),
                    );
                  }
                : () async {
                    // Check if course is free or user has already paid
                    final isFree = course.price == 0;
                    final paymentManager = PaymentManager();
                    
                    if (!isFree) {
                      final hasPaid = await paymentManager.hasUserPaidForCourse(course.courseId);
                      if (!hasPaid) {
                        // Convert price (double) to cents (int) for payment
                        final amountCents = (course.price * 100).round();
                        final success = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              courseId: course.courseId,
                              courseTitle: course.title,
                              amountCents: amountCents,
                              currency: course.currency,
                            ),
                          ),
                        );
                        if (success != true) return; // user backed out
                      }
                    }

                    final err = await _enrollmentManager.enrollInCourse(course.courseId);
                    if (!mounted) return;
                    if (err == null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseContentScreen(
                            courseId: course.courseId,
                            title: course.title,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err), backgroundColor: Colors.red),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: enrolled ? Colors.grey.shade300 : const Color(0xFF4169E1),
              foregroundColor: enrolled ? Colors.black87 : Colors.white,
            ),
            child: Text(enrolled ? 'Open' : 'Enroll'),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedFiltersSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Advanced Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Rating Filter
              const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _minRating ?? 0.0,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: _minRating != null ? _minRating!.toStringAsFixed(1) : 'Any',
                      onChanged: (value) {
                        setModalState(() {
                          _minRating = value > 0 ? value : null;
                        });
                      },
                    ),
                  ),
                  Text(_minRating != null ? _minRating!.toStringAsFixed(1) : 'Any'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Price Filter
              const Text('Maximum Price', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _maxPrice ?? 1000.0,
                      min: 0.0,
                      max: 1000.0,
                      divisions: 20,
                      label: _maxPrice != null ? '\$${_maxPrice!.toInt()}' : 'Any',
                      onChanged: (value) {
                        setModalState(() {
                          _maxPrice = value < 1000 ? value : null;
                        });
                      },
                    ),
                  ),
                  Text(_maxPrice != null ? '\$${_maxPrice!.toInt()}' : 'Any'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _minRating = null;
                          _maxPrice = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _filterCourses();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}