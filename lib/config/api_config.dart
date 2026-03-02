// lib/config/api_config.dart
// API keys should be provided at build time using --dart-define.
// Example: flutter run --dart-define=OPENAI_API_KEY=your_key --dart-define=YOUTUBE_API_KEY=your_key

class ApiConfig {
  static const String openAIApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String openAIApiUrl =
      'https://api.openai.com/v1/chat/completions';

  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: '',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String stripeSecretKey = String.fromEnvironment(
    'STRIPE_SECRET_KEY',
    defaultValue: '',
  );
}
