class GlobalCoupon {
  final String id;
  final String code;
  final int discount;
  final String expiryDate;
  final bool isActive;
  final String createDate;

  GlobalCoupon({
    required this.id,
    required this.code,
    required this.discount,
    required this.expiryDate,
    required this.isActive,
    required this.createDate,
  });

  factory GlobalCoupon.fromJson(Map<String, dynamic> json, String id) {
    return GlobalCoupon(
      id: id,
      code: json['code'] ?? '',
      discount: json['discount'] is int
          ? json['discount']
          : int.tryParse(json['discount'].toString()) ?? 0,
      expiryDate: json['expiryDate'] ?? '',
      isActive: json['isActive'] ?? false,
      createDate: json['createDate'] ?? '',
    );
  }

  bool get isValid {
    if (!isActive) return false;
    try {
      final expiry = DateTime.parse(expiryDate);
      final now = DateTime.now();
      // Compare only dates (YYYY-MM-DD)
      final today = DateTime(now.year, now.month, now.day);
      final exp = DateTime(expiry.year, expiry.month, expiry.day);
      return !exp.isBefore(today);
    } catch (e) {
      return false;
    }
  }
}
