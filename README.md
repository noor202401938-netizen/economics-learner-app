# economics_learner

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firestore Data Model (initial)

- Collection `users/{uid}`
  - `uid` (string)
  - `email` (string)
  - `displayName` (string)
  - `photoURL` (string)
  - `role` (string: `student` | `admin`)
  - `phone` (string)
  - `grade` (string)
  - `interest` (string)
  - `createdAt` (timestamp)
  - `lastLogin` (timestamp)
  - `updatedAt` (timestamp)
  - `isActive` (bool)

- Collections to add next
  - `courses/{courseId}`: metadata, tags, level
  - `courses/{courseId}/lessons/{lessonId}`: content units
  - `enrollments/{docId}` or `users/{uid}/enrollments/{courseId}`
  - `progress/{docId}` or `users/{uid}/progress/{lessonId}`: status, score
  - `quizzes/{quizId}` and `quizSubmissions/{docId}`
  - `certificates/{docId}`
  - `payments/{docId}`
  - `notifications/{docId}`

Security: restrict reads/writes by `uid` ownership and `role` for admin-only operations.