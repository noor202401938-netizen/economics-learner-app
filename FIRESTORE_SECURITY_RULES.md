# Firestore Security Rules

This document contains the Firestore security rules needed for the Economics Learner app to function properly.

## How to Apply These Rules

1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project
3. Navigate to **Firestore Database** > **Rules** tab
4. Copy and paste the rules below
5. Click **Publish**

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Helper function to check if user owns the resource
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users Collection
    match /users/{userId} {
      // Users can read their own profile
      allow read: if isOwner(userId);
      // Users can create their own profile during registration
      allow create: if isAuthenticated() && request.auth.uid == userId;
      // Users can update their own profile (except role)
      allow update: if isOwner(userId) && 
                       (!('role' in request.resource.data.diff(resource.data).affectedKeys()));
      // Only admins can delete user profiles
      allow delete: if isAdmin();
    }

    // Courses Collection
    match /courses/{courseId} {
      // Anyone can read published courses
      // For queries: Firestore checks each document that matches the query filter
      // The !exists() allows checking document existence; resource.data.isPublished checks published status
      allow read: if isAdmin() || 
                     !exists(/databases/$(database)/documents/courses/$(courseId)) ||
                     resource.data.isPublished == true;
      // Only admins can create, update, or delete courses
      allow create, update, delete: if isAdmin();
    }

    // Chat Sessions Collection (for AI Tutor)
    match /chat_sessions/{sessionId} {
      // Users can read their own chat sessions
      allow read: if isAuthenticated() && 
                     (!exists(/databases/$(database)/documents/chat_sessions/$(sessionId)) ||
                      resource.data.userId == request.auth.uid);
      // Users can create their own sessions
      allow create: if isAuthenticated() && 
                        request.resource.data.userId == request.auth.uid;
      // Users can update their own sessions
      allow update: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
      // Users can delete their own sessions
      allow delete: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
    }

    // Chat Messages Collection (for AI Tutor)
    match /chat_messages/{messageId} {
      // Users can only access messages in their own sessions
      allow read: if isAuthenticated() && 
                     get(/databases/$(database)/documents/chat_sessions/$(resource.data.sessionId)).data.userId == request.auth.uid;
      // Users can create messages in their own sessions
      allow create: if isAuthenticated() && 
                       get(/databases/$(database)/documents/chat_sessions/$(request.resource.data.sessionId)).data.userId == request.auth.uid;
    }

    // User Preferences Collection
    match /user_preferences/{userId} {
      // Users can read and write their own preferences
      allow read, write: if isOwner(userId);
    }

    // Enrollments Collection
    match /enrollments/{enrollmentId} {
      // Users can read their own enrollments (using uid field as per repository)
      allow read: if isAuthenticated() && 
                     (!exists(/databases/$(database)/documents/enrollments/$(enrollmentId)) ||
                      resource.data.uid == request.auth.uid);
      // Users can create their own enrollments
      allow create: if isAuthenticated() && 
                        request.resource.data.uid == request.auth.uid;
      // Users can update their own enrollments (for status changes)
      allow update: if isAuthenticated() && 
                       resource.data.uid == request.auth.uid;
      // Only admins can delete enrollments
      allow delete: if isAdmin();
    }

    // Progress Collection
    match /progress/{progressId} {
      // Users can read their own progress (uses userId field)
      allow read: if isAuthenticated() && 
                     (!exists(/databases/$(database)/documents/progress/$(progressId)) ||
                      resource.data.userId == request.auth.uid);
      // Users can create their own progress records
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      // Users can update their own progress
      allow update: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
      // Users can delete their own progress
      allow delete: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
    }

    // Payments Collection (document ID is the uid)
    match /payments/{paymentId} {
      // Users can read their own payments (paymentId is the uid)
      allow read: if isAuthenticated() && 
                     (paymentId == request.auth.uid || isAdmin());
      // Users can create their own payment records
      allow create: if isAuthenticated() && 
                       paymentId == request.auth.uid;
      // Users can update their own payments
      allow update: if isAuthenticated() && 
                       paymentId == request.auth.uid;
      // Only admins can delete payments
      allow delete: if isAdmin();
    }

    // Certificates Collection
    match /certificates/{certificateId} {
      // Users can read their own certificates (uses userId field)
      allow read: if isAuthenticated() && 
                     (!exists(/databases/$(database)/documents/certificates/$(certificateId)) ||
                      resource.data.userId == request.auth.uid);
      // Only admins can create, update, or delete certificates
      allow create, update, delete: if isAdmin();
    }

    // Notifications Collection
    match /notifications/{notificationId} {
      // Users can read their own notifications (uses userId field)
      allow read: if isAuthenticated() && 
                     (!exists(/databases/$(database)/documents/notifications/$(notificationId)) ||
                      resource.data.userId == request.auth.uid);
      // Users can update their own notifications (e.g., mark as read)
      allow update: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
      // Only admins can create notifications
      allow create: if isAdmin();
    }

    // Default: Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Required Firestore Indexes

For optimal performance, create the following composite indexes in Firestore:

1. **Courses Collection:**
   - Collection: `courses`
   - Fields: `isPublished` (Ascending), `createdAt` (Descending)
   - Query scope: Collection

2. **Chat Sessions Collection:**
   - Collection: `chat_sessions`
   - Fields: `userId` (Ascending), `updatedAt` (Descending)
   - Query scope: Collection

3. **Chat Messages Collection:**
   - Collection: `chat_messages`
   - Fields: `sessionId` (Ascending), `timestamp` (Ascending)
   - Query scope: Collection

4. **Enrollments Collection:**
   - Collection: `enrollments`
   - Fields: `uid` (Ascending), `status` (Ascending)
   - Query scope: Collection

## How to Create Indexes

1. Go to Firebase Console
2. Navigate to **Firestore Database** > **Indexes** tab
3. Click **Create Index**
4. Follow the prompts to create each index
5. Wait for the index to build (this may take a few minutes)

Alternatively, when you run queries that require an index, Firebase will provide a link in the error message that you can click to create the index automatically.

## Testing the Rules

After applying the rules:

1. Test as a regular user (student):
   - Should be able to read published courses
   - Should be able to read/write own profile
   - Should be able to read/write own chat sessions and messages
   - Should NOT be able to create/update/delete courses

2. Test as an admin:
   - Should be able to do everything a student can do
   - Should be able to create/update/delete courses
   - Should be able to read all user profiles

## Important Notes

- These rules assume that user roles are stored in the `users/{userId}` document with a `role` field
- Make sure to set at least one user as 'admin' in Firestore manually
- The rules use recursive functions which require `rules_version = '2'`
- Always test rules in the Firebase Console Rules Playground before deploying to production

