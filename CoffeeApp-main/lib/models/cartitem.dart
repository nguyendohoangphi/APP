// ignore_for_file: constant_identifier_names

import 'package:coffeeapp/models/product.dart';

class CartItem {
  String id;
  late String idOrder;
  final String productName;
  late Product product;
  final SizeOption size;
  late int amount;
  double price;

  CartItem({
    this.id = '',
    required this.idOrder,
    required this.productName,
    required this.product,
    required this.amount,
    required this.size,
    this.price = 0.0,
  });

  factory CartItem.fromJson(Map<String, dynamic> json, {String id = ''}) =>
      CartItem(
        id: id,
        idOrder: json['idOrder'],
        productName: json['productName'],
        amount: json['amount'],
        size: stringToEnum(SizeOption.values, json['size']),
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        product: json['product'] != null
            ? Product.fromJson(json['product'])
            : Product(
                createDate: '',
                name: json['productName'] ?? '',
                imageUrl: '',
                description: '',
                rating: 0,
                reviewCount: 0,
                price: (json['price'] as num?)?.toDouble() ?? 0.0,
                type: "Cà phê",
              ),
      );

  Map<String, dynamic> toJson(String idOrder) => {
    'idOrder': idOrder,
    'productName': productName,
    'size': enumToString(size),
    'amount': amount,
    'price': price,
    'product': product.toJson(), // Serialize the full product
  };

  factory CartItem.fromOrderJson(Map<String, dynamic> json) {
    return CartItem(
      id: '',
      idOrder: '',
      productName: json['product']['name'],
      amount: json['quantity'],
      size: stringToEnum(SizeOption.values, json['size']),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      product: Product(
        createDate: '',
        name: json['product']['name'],
        imageUrl: '', // Missing in legacy Order JSON
        description: '',
        rating: 0,
        reviewCount: 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        type: '',
      ),
    );
  }

  Map<String, dynamic> toOrderJson() => {
    'product': {'name': productName},
    'quantity': amount,
    'price': price,
    'totalPrice': price * amount,
    'size': enumToString(size),
  };
}

enum SizeOption { Small, Medium, Large }
