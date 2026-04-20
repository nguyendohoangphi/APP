import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeeapp/models/coupon.dart';
import 'package:coffeeapp/models/global_coupon.dart';
import 'package:coffeeapp/repositories/coupon_repository.dart';
import 'package:coffeeapp/services/table_in_database.dart';

class CouponRepositoryImpl implements ICouponRepository {
  final CollectionReference _couponRef = FirebaseFirestore.instance.collection(
    TableInDatabase.CouponTable,
  );

  @override
  Future<Coupon> getCoupon(String email) async {
    final snapshot = await _couponRef.where('email', isEqualTo: email).get();

    if (snapshot.docs.isNotEmpty) {
      return Coupon.fromJson(
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    } else {
      return Coupon(email: email, codes: []);
    }
  }

  @override
  Future<void> updateCoupon(Coupon coupon) async {
    final snapshot = await _couponRef
        .where('email', isEqualTo: coupon.email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await _couponRef.doc(snapshot.docs.first.id).update(coupon.toJson());
    } else {
      await _couponRef.add(coupon.toJson());
    }
  }

  @override
  Future<List<GlobalCoupon>> getActiveGlobalCoupons() async {
    final CollectionReference globalCouponsRef = FirebaseFirestore.instance
        .collection(TableInDatabase.CouponsTable);

    final snapshot = await globalCouponsRef
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) {
          return GlobalCoupon.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        })
        .where((c) => c.isValid)
        .toList();
  }
}
