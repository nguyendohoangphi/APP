import 'package:coffeeapp/models/revenue.dart';

abstract class IRevenueRepository {
  Future<void> saveRevenue({
    required double amount,
    required String orderId,
    required int productsCount,
    required double profit,
  });
  Stream<List<Revenue>> getRevenueStream();
  Future<List<Revenue>> getRevenueByYear(int year);
  Stream<List<Revenue>> getMonthlyRevenueStream(DateTime date);
}
