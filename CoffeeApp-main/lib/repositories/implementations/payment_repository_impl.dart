import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:coffeeapp/repositories/payment_repository.dart';
import 'package:coffeeapp/repositories/revenue_repository.dart';

const bool kEnableStripeBackend = false;

class PaymentRepositoryImpl implements IPaymentRepository {
  final IRevenueRepository _revenueRepository;

  PaymentRepositoryImpl(this._revenueRepository);

  @override
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
        // VNPay xử lý trực tiếp trên UI WebView, ở đây chỉ ghi nhận doanh thu
      }

      await _revenueRepository.saveRevenue(
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
    throw UnimplementedError('Stripe backend not enabled (demo mode)');
  }
}
