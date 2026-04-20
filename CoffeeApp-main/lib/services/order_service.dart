// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeeapp/models/product.dart';
import 'package:coffeeapp/models/orderitem.dart';
import 'package:coffeeapp/services/table_in_database.dart';
import 'package:intl/intl.dart';

class OrderService {
  final CollectionReference _ordersRef = FirebaseFirestore.instance.collection(
    TableInDatabase.OrderTable,
  );
  final CollectionReference _revenueRef = FirebaseFirestore.instance.collection(
    'revenue',
  );

  Future<void> placeOrderAndUpdateRevenue({required OrderItem order}) async {
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
        })
        .catchError((error) {
          print("Transaction failed: $error");
          throw Exception(
            "Failed to place order. Please try again. Error: $error",
          );
        });
  }

  Future<void> createOrder(OrderItem order) async {
    try {
      final orderDoc = _ordersRef.doc(order.id);
      await orderDoc.set(order.toJson());

      // Also write to cartItems subcollection
      final subRef = orderDoc.collection('cartItems');
      for (var item in order.cartItems) {
        await subRef.add(item.toOrderJson());
      }
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<OrderItem>> getOrdersByEmail(String email) async {
    final snapshot = await _ordersRef.where('email', isEqualTo: email).get();

    if (snapshot.docs.isEmpty) {
      print("No orders found for email: $email");
      return [];
    }

    return snapshot.docs
        .map((doc) => OrderItem.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderItem>> getAllOrders() async {
    final snapshot = await _ordersRef.get();

    if (snapshot.docs.isEmpty) {
      print("No orders found in the database.");
      return [];
    }

    return snapshot.docs
        .map((doc) => OrderItem.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateOrderStatus(String id, StatusOrder newStatus) async {
    try {
      await _ordersRef.doc(id).update({'statusOrder': enumToString(newStatus)});
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _ordersRef.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }
}
