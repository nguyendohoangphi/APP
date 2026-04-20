import 'package:coffeeapp/models/orderitem.dart';

abstract class IOrderRepository {
  Future<void> createOrder(OrderItem order);
  Future<List<OrderItem>> getOrders();
  Future<List<OrderItem>> getOrdersByUser(String email);
  Future<List<OrderItem>> getOrdersByStatus(String status);
  Future<void> updateOrderStatus(String id, String status);
}
