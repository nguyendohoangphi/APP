import 'package:flutter/material.dart';
import 'package:coffeeapp/models/cartitem.dart';
import 'package:coffeeapp/models/coupon.dart';
import 'package:coffeeapp/models/global_data.dart';
import 'package:coffeeapp/models/orderitem.dart';
import 'package:coffeeapp/repositories/auth_repository.dart';
import 'package:coffeeapp/repositories/coupon_repository.dart';
import 'package:coffeeapp/repositories/order_repository.dart';

class UserProvider extends ChangeNotifier {
  final IAuthRepository _authRepository;
  final IOrderRepository _orderRepository;
  final ICouponRepository _couponRepository;

  UserProvider({
    required IAuthRepository authRepository,
    required IOrderRepository orderRepository,
    required ICouponRepository couponRepository,
  }) : _authRepository = authRepository,
       _orderRepository = orderRepository,
       _couponRepository = couponRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentRank = 0;
  int _totalOrders = 0;
  int _totalDrinks = 0;
  double _totalPayment = 0;
  List<String> _drinkList = [];
  List<String> _coupons = [];

  int _nextRank = 0;
  int _pointsToNext = 0;
  double _rankProgress = 0;

  int get currentRank => _currentRank;
  int get totalOrders => _totalOrders;
  int get totalDrinks => _totalDrinks;
  double get totalPayment => _totalPayment;
  List<String> get drinkList => _drinkList;
  List<String> get coupons => _coupons;
  int get nextRank => _nextRank;
  int get pointsToNext => _pointsToNext;
  double get rankProgress => _rankProgress;

  final Map<String, String> ranks = {
    'Hạng đồng': 'assets/images/rank/r1.png',
    'Hạng bạc': 'assets/images/rank/r0.png',
    'Hạng vàng': 'assets/images/rank/r2.png',
    'Hạng kim cương xanh': 'assets/images/rank/r3.png',
    'Hạng kim cương tím': 'assets/images/rank/r4.png',
    'Hạng kim cương đỏ': 'assets/images/rank/r5.png',
  };

  void _resetData() {
    _currentRank = 0;
    _totalOrders = 0;
    _totalDrinks = 0;
    _totalPayment = 0;
    _drinkList = [];
    _coupons = [];
    _rankProgress = 0;
    _pointsToNext = 0;
    _nextRank = 0;
  }

  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _resetData();

      final userProfile = await _authRepository.getProfile();
      if (userProfile != null) {
        GlobalData.userDetail = userProfile;
      } else {
        _isLoading = false;
        notifyListeners();
        return;
      }

      Coupon coupon = await _couponRepository.getCoupon(
        GlobalData.userDetail.email,
      );
      _coupons.addAll(coupon.codes);

      List<OrderItem> orderItemList = await _orderRepository.getOrdersByUser(
        GlobalData.userDetail.email,
      );

      List<CartItem> cartItemList = [];
      for (OrderItem orderItem in orderItemList) {
        cartItemList.addAll(orderItem.cartItems);
      }

      _totalOrders = orderItemList.length;
      for (CartItem cartItem in cartItemList) {
        if (!_drinkList.contains(cartItem.productName)) {
          _drinkList.add(cartItem.productName);
          _totalDrinks++;
        }
      }
      for (OrderItem orderItem in orderItemList) {
        double orderTotal =
            double.tryParse(orderItem.total) ??
            double.tryParse(orderItem.total.replaceAll(RegExp(r'[^\d]'), '')) ??
            0.0;
        _totalPayment += orderTotal;
      }

      switch (GlobalData.userDetail.rank) {
        case 'Hạng đồng':
          _currentRank = 0;
          break;
        case 'Hạng bạc':
          _currentRank = 1;
          break;
        case 'Hạng vàng':
          _currentRank = 2;
          break;
        case 'Hạng kim cương xanh':
          _currentRank = 3;
          break;
        case 'Hạng kim cương tím':
          _currentRank = 4;
          break;
        case 'Hạng kim cương đỏ':
          _currentRank = 5;
          break;
        default:
          _currentRank = 0;
      }

      _nextRank = _currentRank < 5 ? _currentRank + 1 : 5;
      _pointsToNext = (_nextRank * 100) - GlobalData.userDetail.point;
      _rankProgress = GlobalData.userDetail.point / (_nextRank * 100);
      if (_rankProgress > 1) _rankProgress = 1;
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
