class Coupon {
  final String email;
  final List<String> codes;

  Coupon({required this.email, required this.codes});

  factory Coupon.fromJson(Map<String, dynamic> json) {
    String email = json['email'] ?? '';
    List<String> codes = [];

    // Prioritize new structure: { 'email': ..., 'codes': [...] }
    if (json['codes'] is List) {
      codes = (json['codes'] as List).map((e) => e.toString()).toList();
    } else {
      // Legacy fallback: Assuming flat structure where non-email fields are codes
      // e.g. { 'email': ..., 'key1': 'code1', 'key2': 'code2' }
      json.forEach((key, value) {
        if (key != 'email' && value is String && value.isNotEmpty) {
          codes.add(value);
        }
      });
    }

    return Coupon(email: email, codes: codes);
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'codes': codes};
  }
}
