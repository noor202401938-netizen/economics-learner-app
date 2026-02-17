// lib/business_logic/payment_manager.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../repository/payment_repository.dart';
import '../backend/payment_gateway_service.dart';

class PaymentManager {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final PaymentGatewayService _paymentGateway = PaymentGatewayService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  // Check if user has paid for a specific course
  Future<bool> hasUserPaidForCourse(String courseId) async {
    final user = _user;
    if (user == null) return false;
    return _paymentRepository.hasUserPaidForCourse(uid: user.uid, courseId: courseId);
  }

  Stream<bool> watchUserPaidForCourse(String courseId) {
    final user = _user;
    if (user == null) return Stream<bool>.value(false);
    return _paymentRepository.watchUserPaidForCourse(uid: user.uid, courseId: courseId);
  }

  Future<void> startPendingPayment({
    required String courseId,
    required int amountCents,
    String currency = 'USD',
  }) async {
    final user = _user;
    if (user == null) return;
    await _paymentRepository.createPendingPayment(
      uid: user.uid,
      courseId: courseId,
      amountCents: amountCents,
      currency: currency,
    );
  }

  // Legacy method for backward compatibility
  @deprecated
  Future<bool> hasUserPaid() async {
    // No longer used - there's no platform-wide fee
    return false;
  }

  // Process payment with Stripe
  Future<bool> processStripePayment({
    required String courseId,
    required int amountCents,
    String currency = 'USD',
    String? cardNumber,
    String? expiryDate,
    String? cvv,
  }) async {
    try {
      // Create payment intent
      final paymentIntent = await _paymentGateway.createPaymentIntent(
        amountCents: amountCents,
        currency: currency,
      );

      // Process payment
      final success = await _paymentGateway.processPaymentWithCard(
        paymentIntentClientSecret: paymentIntent['client_secret'] ?? paymentIntent['id'],
        cardNumber: cardNumber ?? '',
        expiryDate: expiryDate ?? '',
        cvv: cvv ?? '',
      );

      if (success) {
        await confirmPaidForCourse(courseId);
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> confirmPaidForCourse(String courseId) async {
    final user = _user;
    if (user == null) return;
    await _paymentRepository.markPaidForCourse(uid: user.uid, courseId: courseId);
  }

  // Legacy method for backward compatibility
  @deprecated
  Future<void> confirmPaid() async {
    // No longer used - use confirmPaidForCourse instead
  }
}


