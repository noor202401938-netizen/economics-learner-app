# Economics Learner App

A cross-platform Flutter application for learning economics with AI-powered tutoring, quizzes, and course management.

## Features

- **AI Tutor Chat** — Get personalised economics explanations via an integrated AI tutor
- **AI Quiz Engine** — Adaptive quizzes generated based on course content
- **Course Management** — Browse, enrol in, and track progress through economics courses
- **Video Lessons** — YouTube-integrated video player with progress tracking
- **Certificates** — Generate downloadable PDF certificates on course completion
- **Admin Dashboard** — Create and manage courses, upload XML-based lesson content
- **Notifications** — Push notifications via Firebase Cloud Messaging
- **Payments** — Stripe payment integration for paid courses
- **Accessibility** — Theme customisation, font-size scaling, and high-contrast mode

## Supported Platforms

| Platform | Status |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Linux | ✅ |

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0.0
- A [Firebase project](https://console.firebase.google.com/) with Authentication, Firestore, Storage, Messaging, Analytics, and Crashlytics enabled
- A [Stripe](https://stripe.com/) account for payment processing

## Getting Started

1. **Clone the repository**

   ```bash
   git clone <repo-url>
   cd economics-learner-app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   Run [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) to generate `lib/firebase_options.dart` for your own Firebase project:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Also place your platform-specific Firebase config files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

4. **Configure Stripe** — Set your Stripe publishable key in `lib/config/api_config.dart`.

5. **Run the app**

   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── backend/          # Firebase Auth, Firestore, Storage, YouTube, XML parser
├── business_logic/   # Managers & engines (auth, course, AI, payment, etc.)
├── config/           # API configuration
├── model/            # Data models (course, quiz, certificate, etc.)
├── repository/       # Data access layer
├── screens/          # UI screens (student & admin views)
├── utils/            # Utilities (theme, PDF generator, preference notifier)
├── widgtes/          # Reusable widgets (note: folder name matches source directory)
├── firebase_options.dart
└── main.dart
assets/
├── logo.png
├── google.png
└── course_content_template.xml
```

## Firestore Data Model

- `users/{uid}` — user profile, role (`student` | `admin`), preferences
- `courses/{courseId}` — course metadata, tags, level, price
- `courses/{courseId}/lessons/{lessonId}` — lesson content units
- `enrollments/{docId}` — enrolment records
- `progress/{docId}` — lesson completion status and scores
- `quizzes/{quizId}` / `quizSubmissions/{docId}` — quiz data
- `certificates/{docId}` — issued certificates
- `payments/{docId}` — payment records
- `notifications/{docId}` — user notifications

See `FIRESTORE_SECURITY_RULES.md` for recommended security rules.

## Running Tests

```bash
flutter test
```

## Additional Guides

- [Firestore Security Rules](FIRESTORE_SECURITY_RULES.md)
- [Payment Setup](PAYMENT_SETUP_GUIDE.md)
- [XML Course Content Guide](XML_COURSE_GUIDE.md)
- [Video Player Setup](VIDEO_PLAYER_SETUP.md)