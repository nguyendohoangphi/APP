// ignore_for_file: curly_braces_in_flow_control_structures, avoid_print

import 'package:coffeeapp/models/cartitem.dart';
import 'package:coffeeapp/models/coupon.dart';
//import 'package:coffeeapp/models/global_coupon.dart';
import 'package:coffeeapp/models/global_data.dart';
import 'package:coffeeapp/models/orderitem.dart';
//import 'package:coffeeapp/models/tablestatus.dart';
import 'package:coffeeapp/repositories/auth_repository.dart';
import 'package:coffeeapp/repositories/cart_repository.dart';
import 'package:coffeeapp/repositories/coupon_repository.dart';
import 'package:coffeeapp/repositories/order_repository.dart';
import 'package:coffeeapp/repositories/payment_repository.dart';
import 'package:coffeeapp/repositories/table_repository.dart';
import 'package:coffeeapp/services/cart_storage_service.dart';
import 'package:coffeeapp/utils/generateCouponCode.dart';
import 'package:coffeeapp/utils/generateCustomId.dart';
import 'package:coffeeapp/utils/getCurrentFormattedDateTime.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:coffeeapp/screens/Order/vnpay_screen.dart';
import 'package:coffeeapp/services/vnpay_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];
  final CartStorageService _storageService = CartStorageService();

  // Coupon Logic
  final Map<String, int> _availableCoupons = {};
  String _appliedCouponCode = '';
  int _currentDiscountPercent = 0;

  CartProvider() {
    _loadCart();
  }

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  Map<String, int> get availableCoupons => _availableCoupons;
  String get appliedCouponCode => _appliedCouponCode;
  int get currentDiscountPercent => _currentDiscountPercent;

  double get subTotal => _cartItems.fold(
    0,
    (sum, item) => sum + (item.product.price * item.amount),
  );

  double get discountAmount => subTotal * (_currentDiscountPercent / 100);
  double get total =>
      subTotal - discountAmount + 10000; // 10000 service fee constant

  Future<void> _loadCart() async {
    final storedItems = await _storageService.loadCart();
    if (storedItems.isNotEmpty) {
      _cartItems.clear();
      _cartItems.addAll(storedItems);
      notifyListeners();
    }
  }

  // --- Coupon Logic ---
  Future<void> loadCoupons(
    ICouponRepository couponRepo,
    String userEmail,
  ) async {
    _availableCoupons.clear();
    try {
      // 1. User Specific
      Coupon coupon = await couponRepo.getCoupon(userEmail);
      for (var code in coupon.codes) {
        _availableCoupons[code] = 10; // Default 10%
      }
      // 2. Global
      final globalCoupons = await couponRepo.getActiveGlobalCoupons();
      for (var gc in globalCoupons) {
        _availableCoupons[gc.code] = gc.discount;
      }
      notifyListeners();
    } catch (e) {
      print("Error loading coupons: $e");
    }
  }

  void applyCoupon(String code) {
    if (_availableCoupons.containsKey(code)) {
      _appliedCouponCode = code;
      _currentDiscountPercent = _availableCoupons[code]!;
    } else {
      _appliedCouponCode = '';
      _currentDiscountPercent = 0;
    }
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCouponCode = '';
    _currentDiscountPercent = 0;
    notifyListeners();
  }

  // --- Cart Management ---
  void addToCart(CartItem item) {
    bool found = false;
    for (var existing in _cartItems) {
      if (existing.productName == item.productName &&
          existing.size == item.size) {
        existing.amount += item.amount;
        found = true;
        break;
      }
    }
    if (!found) _cartItems.add(item);

    notifyListeners();
    _storageService.saveCart(_cartItems);
  }

  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
    if (_cartItems.isEmpty) removeCoupon();
    notifyListeners();
    _storageService.saveCart(_cartItems);
  }

  void clearCart() {
    _cartItems.clear();
    removeCoupon();
    notifyListeners();
    _storageService.clearCart();
  }

  void incrementItem(CartItem item) {
    item.amount++;
    notifyListeners();
    _storageService.saveCart(_cartItems);
  }

  void decrementItem(CartItem item) {
    if (item.amount > 1) {
      item.amount--;
      notifyListeners();
      _storageService.saveCart(_cartItems);
    }
  }

  // --- Checkout Logic ---
  Future<bool> processCheckout({
    required BuildContext
    context, // Needed for showing SnackBars if we keep UI logic here, better to return status
    required String name,
    required String phone,
    required String note,
    required String tableName,
    required String tableId,
    required IOrderRepository orderRepo,
    required ICartRepository cartRepo,
    required IPaymentRepository paymentRepo,
    required ITableRepository tableRepo,
    required IAuthRepository authRepo,
    required ICouponRepository couponRepo,
    required String userEmail,
  }) async {
    if (_cartItems.isEmpty) return false;

    final orderItem = OrderItem(
      id: generateCustomId(),
      timeOrder: getCurrentFormattedDateTime(),
      cartItems: List.from(_cartItems), // Copy list
      statusOrder: StatusOrder.Waiting,
      createDate: DateFormat('dd/MM/yyyy – HH:mm:ss').format(DateTime.now()),
      email: userEmail,
      table: tableName,
      phone: phone,
      name: name,
      total: total.toString(),
      coupon: _appliedCouponCode,
      note: note,
    );

    int totalProducts = _cartItems.fold(0, (sum, item) => sum + item.amount);
    double currentProfit =
        _cartItems.length *
        10000; // 10k service fee per item type? Or total? Logic was length * 10k

    // --- Tích hợp VNPay ---
    final String? paymentUrl = await VNPayService.generatePaymentUrl(
      amount: total,
      orderInfo: 'Thanh toan don hang ${orderItem.id}',
      orderId: orderItem.id,
    );

    if (paymentUrl == null) {
      return false; // Lỗi tạo link thanh toán từ server
    }

    if (!context.mounted) return false;

    final bool? isPaid = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VNPayScreen(
          paymentUrl: paymentUrl,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );

    if (isPaid != true) {
      return false; // Hủy thanh toán hoặc thất bại
    }

    bool paymentSuccess = await paymentRepo.processPayment(
      amount: total,
      orderId: orderItem.id,
      productsCount: totalProducts,
      profit: currentProfit,
    );

    if (paymentSuccess) {
      try {
        await orderRepo.createOrder(orderItem);
        for (var item in _cartItems) {
          item.idOrder = orderItem.id;
          await cartRepo.addCartItem(item);
        }

        // Update User Points
        await _updateUserPointsAndRank(authRepo, couponRepo, userEmail);

        // Update Table
        if (tableId.isNotEmpty) {
          await tableRepo.updateBookingStatus(tableId, true);
        }

        clearCart(); // Auto saves to local storage
        return true;
      } catch (e) {
        print("Checkout Error: $e");
        rethrow;
      }
    }
    return false;
  }

  Future<void> _updateUserPointsAndRank(
    IAuthRepository authRepo,
    ICouponRepository couponRepo,
    String email,
  ) async {
    // Logic from cart.dart
    int pointsFromOrder = _cartItems.fold(0, (sum, item) => sum + item.amount);
    GlobalData.userDetail.point += pointsFromOrder;

    String currentRank = GlobalData.userDetail.rank;
    String newRank = currentRank;

    if (GlobalData.userDetail.point >= 600)
      newRank = 'Hạng kim cương đỏ';
    else if (GlobalData.userDetail.point >= 500)
      newRank = 'Hạng kim cương tím';
    else if (GlobalData.userDetail.point >= 400)
      newRank = 'Hạng kim cương xanh';
    else if (GlobalData.userDetail.point >= 300)
      newRank = 'Hạng vàng';
    else if (GlobalData.userDetail.point >= 200)
      newRank = 'Hạng bạc';

    GlobalData.userDetail.rank = newRank;

    if (currentRank != newRank) {
      Coupon coupon = await couponRepo.getCoupon(email);
      coupon.codes.add(generateCouponCode());
      await couponRepo.updateCoupon(coupon);
    }

    await authRepo.updateUserPointAndRank(
      email,
      GlobalData.userDetail.point,
      newRank,
    );

    if (_appliedCouponCode.isNotEmpty) {
      // NOTE: Only remove if it's a personal coupon?
      // If Global, we shouldn't remove it usually.
      // Logic from cart.dart removed it unconditionally.
      // Checking if it is in user coupons might be needed.
      Coupon coupon = await couponRepo.getCoupon(email);
      if (coupon.codes.contains(_appliedCouponCode)) {
        coupon.codes.remove(_appliedCouponCode);
        await couponRepo.updateCoupon(coupon);
      }
    }
  }
}
