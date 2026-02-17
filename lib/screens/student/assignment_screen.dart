// lib/screens/student/assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../business_logic/ai_feedback_engine.dart';
import '../../business_logic/certificate_manager.dart';
import '../../repository/quiz_repository.dart';
import '../../model/quiz_model.dart';
import 'certificate_screen.dart';

class AssignmentScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String moduleId;
  final String moduleTitle;
  final String lessonId;
  final String lessonTitle;

  const AssignmentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.moduleId,
    required this.moduleTitle,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final AIFeedbackEngine _feedbackEngine = AIFeedbackEngine();
  final QuizRepository _quizRepository = QuizRepository();
  final CertificateManager _certificateManager = CertificateManager();
  final TextEditingController _submissionController = TextEditingController();
  bool _certificateShown = false;

  AssignmentModel? _assignment;
  AssignmentSubmissionModel? _existingSubmission;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    setState(() => _isLoading = true);
    try {
      _assignment = await _quizRepository.getAssignmentByLessonId(widget.lessonId);

      // Check for existing submission
      if (_assignment != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _existingSubmission = await _quizRepository.getUserAssignmentSubmission(
            userId: user.uid,
            assignmentId: _assignment!.assignmentId,
          );

          if (_existingSubmission != null) {
            _submissionController.text = _existingSubmission!.content;
            if (_existingSubmission!.isGraded) {
              _showFeedback = true;
            }
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assignment: $e')),
        );
      }
    }
  }

  Future<void> _submitAssignment() async {
    final content = _submissionController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your submission')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _assignment == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Generate AI feedback
      final feedback = await _feedbackEngine.generateAssignmentFeedback(
        assignmentTitle: _assignment!.title,
        assignmentInstructions: _assignment!.instructions,
        studentSubmission: content,
        maxPoints: _assignment!.maxPoints,
      );

      // Extract score from feedback
      final score = _feedbackEngine.extractScoreFromFeedback(
        feedback,
        _assignment!.maxPoints,
      );

      // Create submission
      final submission = AssignmentSubmissionModel(
        submissionId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        assignmentId: _assignment!.assignmentId,
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        lessonId: widget.lessonId,
        content: content,
        feedback: feedback,
        score: score,
        isGraded: true,
        submittedAt: DateTime.now(),
        gradedAt: DateTime.now(),
      );

      // Save submission
      await _quizRepository.submitAssignment(submission);

      setState(() {
        _existingSubmission = submission;
        _showFeedback = true;
        _isSubmitting = false;
      });

      // Generate and show certificate
      if (!_certificateShown) {
        _certificateShown = true;
        _showCertificate();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting assignment: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_assignment?.title ?? 'Assignment'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignment == null
              ? const Center(child: Text('Assignment not found'))
              : _showFeedback && _existingSubmission != null
                  ? _buildFeedbackView()
                  : _buildAssignmentView(),
    );
  }

  Widget _buildAssignmentView() {
    final isOverdue = _assignment!.dueDate.isBefore(DateTime.now());
    final daysUntilDue = _assignment!.dueDate.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assignment info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _assignment!.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_assignment!.description.isNotEmpty) ...[
                    Text(
                      _assignment!.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOverdue
                            ? 'Overdue'
                            : daysUntilDue == 0
                                ? 'Due today'
                                : daysUntilDue == 1
                                    ? 'Due tomorrow'
                                    : 'Due in $daysUntilDue days',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${_assignment!.maxPoints} points',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          if (_assignment!.instructions.isNotEmpty) ...[
            const Text(
              'Instructions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                _assignment!.instructions,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Submission field
          const Text(
            'Your Submission',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _submissionController,
            maxLines: 15,
            decoration: InputDecoration(
              hintText: 'Type your assignment submission here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Assignment',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score card
          if (_existingSubmission!.score != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[400]!,
                    Colors.blue[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_turned_in,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_existingSubmission!.score} / ${_assignment!.maxPoints}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Points Earned',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Feedback
          const Text(
            'Feedback',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              _existingSubmission!.feedback ?? 'No feedback available',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),

          const SizedBox(height: 24),

          // Your submission
          const Text(
            'Your Submission',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              _existingSubmission!.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),

          const SizedBox(height: 24),

          // Done button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCertificate() async {
    try {
      final certificate = await _certificateManager.generateCertificate(
        courseId: widget.courseId,
        courseName: widget.courseTitle,
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
      );

      if (certificate != null && mounted) {
        // Show certificate after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CertificateScreen(certificate: certificate),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error showing certificate: $e');
    }
  }
}

