import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/order.dart';

class LoyaltyProvider with ChangeNotifier {
  bool _isRedeeming = false;
  bool get isRedeeming => _isRedeeming;

  /// Redeems free coffee(s) for [userId].
  /// [pointsToRedeem] must be a multiple of 10.
  /// [rewardOrder] is the pre-built Order object (with isFreeRedemption:true).
  /// Returns the Firestore document ID of the created order.
  Future<String> redeemFreeItem(String userId, Order rewardOrder,
      {int pointsToRedeem = 10}) async {
    _isRedeeming = true;
    notifyListeners();
    try {
      final orderId = await FirebaseService.instance
          .redeemFreeItem(userId, rewardOrder, pointsToRedeem: pointsToRedeem);
      return orderId;
    } catch (e) {
      if (kDebugMode) print('Error redeeming free item: $e');
      rethrow;
    } finally {
      _isRedeeming = false;
      notifyListeners();
    }
  }
}
