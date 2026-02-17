// lib/business_logic/video_manager.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repository/progress_repository.dart';
import '../backend/youtube_service.dart';
import '../model/video_progress_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoManager {
  final ProgressRepository _progressRepository = ProgressRepository();
  final YouTubeService _youtubeService = YouTubeService();

  // OpenAI API Configuration
  static const String _openAIApiKey =
      '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';
  static const String _openAIApiUrl =
      'https://api.openai.com/v1/chat/completions';

  // Get video progress for a lesson
  Future<VideoProgressModel?> getVideoProgress({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      return await _progressRepository.getVideoProgress(
        userId: user.uid,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
      );
    } catch (e) {
      throw Exception('Failed to get video progress: $e');
    }
  }

  // Save video progress
  Future<void> saveProgress({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String videoURL,
    required int currentPosition,
    required int totalDuration,
    bool isCompleted = false,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _progressRepository.saveVideoProgress(
        userId: user.uid,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
        videoURL: videoURL,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        isCompleted: isCompleted,
      );
    } catch (e) {
      throw Exception('Failed to save progress: $e');
    }
  }

  // Mark video as completed
  Future<void> markVideoCompleted({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _progressRepository.markVideoCompleted(
        userId: user.uid,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
      );
    } catch (e) {
      throw Exception('Failed to mark video as completed: $e');
    }
  }

  // Get video captions
  Future<VideoCaptionModel?> getVideoCaptions(String videoURL,
      {String language = 'en'}) async {
    try {
      final videoId = YouTubeService.extractVideoId(videoURL);
      if (videoId == null) return null;

      return await _youtubeService.getVideoCaptions(videoId,
          language: language);
    } catch (e) {
      // Return null if captions can't be fetched (graceful degradation)
      return null;
    }
  }

  // Generate AI summary for video using OpenAI
  Future<VideoSummaryModel?> generateAISummary(
      String videoURL, String videoTitle) async {
    try {
      final videoId = YouTubeService.extractVideoId(videoURL) ?? '';

      // Prepare the prompt for OpenAI
      final prompt = '''
Please provide a comprehensive summary and key points for this educational video:

Title: $videoTitle

Please provide:
1. A detailed summary (2-3 paragraphs) of what this video likely covers based on its title
2. 3-5 key learning points that students should take away

Format your response as JSON with the following structure:
{
  "summary": "Your detailed summary here",
  "keyPoints": ["Point 1", "Point 2", "Point 3", "Point 4", "Point 5"]
}
''';

      // Make API call to OpenAI
      final response = await http.post(
        Uri.parse(_openAIApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an educational assistant that provides clear, concise summaries and key learning points for educational videos.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData['choices'][0]['message']['content'];

        // Try to parse JSON from the response
        try {
          // Extract JSON from markdown code blocks if present
          String jsonContent = content;
          if (content.contains('```json')) {
            jsonContent = content.split('```json')[1].split('```')[0].trim();
          } else if (content.contains('```')) {
            jsonContent = content.split('```')[1].split('```')[0].trim();
          }

          final summaryData = json.decode(jsonContent);

          return VideoSummaryModel(
            videoId: videoId,
            summary: summaryData['summary'] ?? content,
            keyPoints: List<String>.from(summaryData['keyPoints'] ?? []),
            generatedAt: DateTime.now(),
          );
        } catch (e) {
          // If JSON parsing fails, use the raw content as summary
          final lines = content
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();
          final summary = lines.isNotEmpty ? lines[0] : content;
          final keyPoints = lines.length > 1
              ? lines.sublist(1).take(5).toList()
              : [
                  'Key learning point 1',
                  'Key learning point 2',
                  'Key learning point 3'
                ];

          return VideoSummaryModel(
            videoId: videoId,
            summary: summary,
            keyPoints: keyPoints,
            generatedAt: DateTime.now(),
          );
        }
      } else {
        // If API call fails, return a basic summary
        return VideoSummaryModel(
          videoId: videoId,
          summary:
              'Unable to generate AI summary at this time. Please try again later.',
          keyPoints: [
            'Review the video content carefully',
            'Take notes on important concepts',
            'Practice applying what you learned',
          ],
          generatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      // Return null on error (graceful degradation)
      return null;
    }
  }

  // Get course completion percentage
  Future<double> getCourseCompletion({
    required String courseId,
    required int totalLessons,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0.0;

      return await _progressRepository.getCourseCompletionPercentage(
        userId: user.uid,
        courseId: courseId,
        totalLessons: totalLessons,
      );
    } catch (e) {
      return 0.0;
    }
  }

  // Watch video progress in real-time
  Stream<VideoProgressModel?> watchVideoProgress({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return Stream.value(null);

      return _progressRepository.watchVideoProgress(
        userId: user.uid,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
      );
    } catch (e) {
      return Stream.value(null);
    }
  }

  // Extract YouTube video ID from URL
  String? extractVideoId(String url) {
    return YouTubeService.extractVideoId(url);
  }
}
