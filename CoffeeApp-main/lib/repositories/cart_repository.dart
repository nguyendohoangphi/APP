import 'package:coffeeapp/models/cartitem.dart';

abstract class ICartRepository {
  Future<List<CartItem>> getCartItems(String idOrder);
  Future<void> addCartItem(CartItem cartItem);
  Future<void> deleteCartItem(String id);
  Future<void> deleteCartItemByIdProduct(String idProduct);
}
