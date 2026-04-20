import 'package:coffeeapp/models/tablestatus.dart';

abstract class ITableRepository {
  Future<List<TableStatus>> getTablesByBookingStatus(bool isBooked);
  Future<void> updateBookingStatus(String tableId, bool isBooked);
}
