import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeeapp/models/product.dart';
import 'package:coffeeapp/repositories/product_repository.dart';
import 'package:coffeeapp/services/table_in_database.dart';
import 'package:flutter/material.dart';

class ProductRepositoryImpl implements IProductRepository {
  final CollectionReference _productRef = FirebaseFirestore.instance.collection(
    TableInDatabase.ProductsTable,
  );

  @override
  Future<void> createProduct(Product product) async {
    try {
      await _productRef.add(product.toJson());
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<Product> getProductByName(String name) async {
    try {
      final querySnapshot = await _productRef
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Product with name "$name" not found');
      }

      final data = querySnapshot.docs.first.data();
      return Product.fromJson(
        data as Map<String, dynamic>,
        id: querySnapshot.docs.first.id,
      );
    } catch (e, stackTrace) {
      debugPrint('Error getting product by name: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _productRef.get();

      if (snapshot.docs.isEmpty) {
        debugPrint("No products found in collection");
        return [];
      }

      return snapshot.docs
          .map((doc) {
            try {
              return Product.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              );
            } catch (e) {
              debugPrint("Lỗi data sản phẩm (ID: ${doc.id}): $e");
              return null;
            }
          })
          .where((item) => item != null)
          .cast<Product>()
          .toList();
    } catch (e) {
      debugPrint("Lỗi lấy danh sách sản phẩm: $e");
      return [];
    }
  }

  @override
  Future<List<Product>> searchProductsByName(String query) async {
    try {
      final snapshot = await _productRef.get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final keyword = query.trim().toLowerCase();

      return snapshot.docs
          .map((doc) {
            try {
              return Product.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              );
            } catch (e) {
              debugPrint("Lỗi parse sản phẩm search: ${doc.id}");
              return null;
            }
          })
          .where((product) => product != null)
          .cast<Product>()
          .where((product) {
            return product.name.toLowerCase().contains(keyword);
          })
          .toList();
    } catch (e) {
      debugPrint("Lỗi tìm kiếm: $e");
      return [];
    }
  }

  @override
  Future<List<Product>> getProductsByType(String type) async {
    final snapshot = await _productRef.where('type', isEqualTo: type).get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs
        .map(
          (doc) =>
              Product.fromJson(doc.data() as Map<String, dynamic>, id: doc.id),
        )
        .toList();
  }

  @override
  Future<List<Product>> getTop10RatedProducts() async {
    final snapshot = await _productRef
        .orderBy('rating', descending: true)
        .limit(10)
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs
        .map(
          (doc) =>
              Product.fromJson(doc.data() as Map<String, dynamic>, id: doc.id),
        )
        .toList();
  }

  @override
  Future<List<Product>> get5NewestProducts() async {
    final snapshot = await _productRef
        .orderBy('createDate', descending: true)
        .limit(5)
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs
        .map(
          (doc) =>
              Product.fromJson(doc.data() as Map<String, dynamic>, id: doc.id),
        )
        .toList();
  }

  @override
  Future<void> updateProductByName(String name, Product product) async {
    try {
      final snapshot = await _productRef
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docRef = snapshot.docs.first.reference;
        await docRef.update(product.toJson());
      } else {
        throw Exception('Product with name "$name" not found.');
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProductByName(String name) async {
    try {
      final snapshot = await _productRef.where('name', isEqualTo: name).get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete product(s) with name "$name": $e');
    }
  }
}
