import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeeapp/models/orderitem.dart';

import 'package:coffeeapp/repositories/order_repository.dart';
import 'package:coffeeapp/services/table_in_database.dart';
import 'package:intl/intl.dart';

class OrderRepositoryImpl implements IOrderRepository {
  final CollectionReference _ordersRef = FirebaseFirestore.instance.collection(
    TableInDatabase.OrderTable,
  );
  final CollectionReference _revenueRef = FirebaseFirestore.instance.collection(
    'revenue',
  );

  @override
  Future<void> createOrder(OrderItem order) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String todayDocId = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final DocumentReference orderRef = _ordersRef.doc(order.id);
    final DocumentReference revenueRef = _revenueRef.doc(todayDocId);

    return firestore
        .runTransaction((transaction) async {
          double orderTotal = double.tryParse(order.total) ?? 0.0;

          transaction.set(revenueRef, {
            'totalRevenue': FieldValue.increment(orderTotal),
            'totalOrders': FieldValue.increment(1),
            'orderIds': FieldValue.arrayUnion([order.id]),
            'date': Timestamp.now(),
          }, SetOptions(merge: true));

          transaction.set(orderRef, order.toJson());

          // Legacy note: Original OrderService.createOrder wrote to 'cartItems' subcollection.
          // However, OrderItem.toJson() already includes cartItems as a list in the main document.
          // We stick to the single-document approach for atomicity and simplicity.
        })
        .catchError((error) {
          throw Exception("Failed to place order: $error");
        });
  }

  @override
  Future<List<OrderItem>> getOrders() async {
    final snapshot = await _ordersRef.get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs
        .map((doc) => OrderItem.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<OrderItem>> getOrdersByUser(String email) async {
    final snapshot = await _ordersRef.where('email', isEqualTo: email).get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs
        .map((doc) => OrderItem.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<OrderItem>> getOrdersByStatus(String status) async {
    final snapshot = await _ordersRef
        .where('statusOrder', isEqualTo: status)
        .get();

    return snapshot.docs
        .map((doc) => OrderItem.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateOrderStatus(String id, String status) async {
    try {
      await _ordersRef.doc(id).update({'statusOrder': status});
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
