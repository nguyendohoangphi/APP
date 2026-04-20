import 'package:coffeeapp/models/product.dart';

abstract class IProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> getProductByName(String name);
  Future<List<Product>> searchProductsByName(String query);
  Future<List<Product>> getProductsByType(String type);
  Future<List<Product>> getTop10RatedProducts();
  Future<List<Product>> get5NewestProducts();
  Future<void> createProduct(Product product);
  Future<void> updateProductByName(String name, Product product);
  Future<void> deleteProductByName(String name);
}
