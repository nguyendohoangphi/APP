import 'package:coffeeapp/models/coupon.dart';
import 'package:coffeeapp/models/global_coupon.dart';

abstract class ICouponRepository {
  Future<Coupon> getCoupon(String email);
  Future<void> updateCoupon(Coupon coupon);
  Future<List<GlobalCoupon>> getActiveGlobalCoupons();
}
