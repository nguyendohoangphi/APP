
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeeapp/models/cartitem.dart';
import 'package:coffeeapp/services/table_in_database.dart';

class CartService {
  final CollectionReference _cartRef = FirebaseFirestore.instance.collection(
    TableInDatabase.CartItemTable,
  );


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


  Future<List<CartItem>> getCartItemsByOrder(String idOrder) async {
    final snapshot = await _cartRef.where('idOrder', isEqualTo: idOrder).get();

    if (snapshot.docs.isEmpty) {
      print("No cart items found for order ID: $idOrder");
      return [];
    }

    return snapshot.docs
        .map(
          (doc) =>
              CartItem.fromJson(doc.data() as Map<String, dynamic>, id: doc.id),
        )
        .toList();
  }


  Future<void> updateCartItemAmount(String docId, int newAmount) async {
    try {
      await _cartRef.doc(docId).update({'amount': newAmount});
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }


  Future<void> deleteCartItem(String docId) async {
    try {
      await _cartRef.doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete cart item: $e');
    }
  }
}
