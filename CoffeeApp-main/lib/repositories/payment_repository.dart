abstract class IPaymentRepository {
  Future<bool> processPayment({
    required double amount,
    required String orderId,
    required int productsCount,
    required double profit,
  });
}
