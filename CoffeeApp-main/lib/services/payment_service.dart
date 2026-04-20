
import 'package:flutter_stripe/flutter_stripe.dart';

import 'revenue_service.dart';


const bool kEnableStripeBackend = false;

class PaymentService {



  Future<bool> processPayment({
    required double amount,
    required String orderId,
    required int productsCount,
    required double profit,
  }) async {
    try {
      if (kEnableStripeBackend) {
        final clientSecret = await _createPaymentIntent(
          amount: amount,
          currency: 'vnd',
        );

        if (clientSecret == null) {
          throw Exception('No client secret');
        }

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Coffee App',
          ),
        );

        await Stripe.instance.presentPaymentSheet();
      } else {

        await Future.delayed(const Duration(seconds: 2));
      }

      await RevenueService.saveRevenue(
        amount: amount,
        orderId: orderId,
        productsCount: productsCount,
        profit: profit,
      );

      return true;
    } catch (e) {
      return false;
    }
  }


  Future<String?> _createPaymentIntent({
    required double amount,
    required String currency,
  }) async {
    throw UnimplementedError(
      'Stripe backend not enabled (demo mode)',
    );
  }
}
