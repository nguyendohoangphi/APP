import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeeapp/models/cartitem.dart';
import 'package:coffeeapp/repositories/cart_repository.dart';
import 'package:coffeeapp/services/table_in_database.dart';
import 'package:flutter/material.dart';

class CartRepositoryImpl implements ICartRepository {
  final CollectionReference _cartRef = FirebaseFirestore.instance.collection(
    TableInDatabase.CartItemTable,
  );

  @override
  Future<void> addCartItem(CartItem item) async {
    try {
      final productQuery = await FirebaseFirestore.instance
          .collection(TableInDatabase.ProductsTable)
          .where('name', isEqualTo: item.productName)
          .limit(1)
          .get();

      if (productQuery.docs.isNotEmpty) {
        final productData = productQuery.docs.first.data();
        final currentPrice = (productData['price'] as num).toDouble();
        item.price = currentPrice;
      }

      await _cartRef.add(item.toJson(item.idOrder));
    } catch (e) {
      throw Exception('Failed to add cart item: $e');
    }
  }

  @override
  Future<List<CartItem>> getCartItems(String idOrder) async {
    try {
      final snapshot = await _cartRef
          .where('idOrder', isEqualTo: idOrder)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint("No cart items found for order ID: $idOrder");
        return [];
      }

      return snapshot.docs
          .map(
            (doc) => CartItem.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error getting cart items: $e");
      return [];
    }
  }

  @override
  Future<void> deleteCartItem(String id) async {
    try {
      await _cartRef.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete cart item: $e');
    }
  }

  @override
  Future<void> deleteCartItemByIdProduct(String idProduct) async {
    try {
      final snapshot = await _cartRef
          .where('idProduct', isEqualTo: idProduct)
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception("Failed to delete cart item by product ID: $e");
    }
  }
}
