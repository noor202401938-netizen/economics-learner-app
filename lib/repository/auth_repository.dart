// lib/repository/auth_repository.dart
import '../backend/firebase_auth_service.dart';
import '../backend/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> registerUser(String email, String password) async {
    final user = await _firebaseAuthService.signUp(email, password);

    if (user != null) {
      // Create user profile in Firestore
      await _firestoreService.createUserProfile(
        uid: user.uid,
        email: email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        role: 'student', // default role
      );
    }

    return user;
  }

  Future<User?> loginUser(String email, String password) async {
    final user = await _firebaseAuthService.signIn(email, password);

    if (user != null) {
      // Update last login time
      await _firestoreService.updateLastLogin(user.uid);
    }

    return user;
  }

  Future<void> logoutUser() {
    return _firebaseAuthService.signOut();
  }

  User? getCurrentUser() {
    return _firebaseAuthService.getCurrentUser();
  }

  // Get user role
  Future<String> getUserRole(String uid) async {
    return await _firestoreService.getUserRole(uid);
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return await _firestoreService.getUserProfile(uid);
  }

  // Google Sign-In with Firestore profile creation
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Cancelled by user';

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // Check if user profile exists, if not create it
      bool exists = await _firestoreService.userExists(userCredential.user!.uid);

      if (!exists) {
        await _firestoreService.createUserProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName,
          photoURL: userCredential.user!.photoURL,
          role: 'student',
        );
      } else {
        // Update last login
        await _firestoreService.updateLastLogin(userCredential.user!.uid);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong: $e';
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Send password reset email
  Future<String?> sendPasswordResetEmail(String email) async {
    return await _firebaseAuthService.sendPasswordResetEmail(email);
  }
}