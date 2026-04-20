import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class VNPayService {
  // local url to test: "http://10.0.2.2:8080/create_payment_url" (Android) or "http://127.0.0.1:8080/create_payment_url" (iOS)
  static const String apiUrl =
      "https://vnpay-backend-w6nt.onrender.com/create_payment_url";
  static const String hashSecret = "3GKF0L4CZTQ12YR7P3AU18S07BW9RFX1";

  static Future<String?> generatePaymentUrl({
    required double amount,
    required String orderInfo,
    String? orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": amount,
          "orderInfo": orderInfo,
          "orderId": orderId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['paymentUrl'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Hàm xác thực tính toàn vẹn của dữ liệu trả về từ VNPay (Return URL / IPN)
  static bool verifyChecksum(Map<String, String> responseParams) {
    final Map<String, String> params = Map<String, String>.from(responseParams);

    // Lấy ra hash do VNPay return and delete nó khỏi list biến cần hash
    final String? vnpSecureHash = params.remove('vnp_SecureHash');
    params.remove('vnp_SecureHashType');

    if (vnpSecureHash == null || vnpSecureHash.isEmpty) {
      return false;
    }

    // Sort lại như lúc tạo URL
    final sortedKeys = params.keys.toList()..sort();
    final Map<String, String> sortedParams = {
      for (var key in sortedKeys) key: params[key]!,
    };

    final List<String> queryData = [];
    sortedParams.forEach((key, value) {
      if (value.isNotEmpty) {
        queryData.add('$key=$value');
      }
    });

    final String queryString = queryData.join('&');
    final List<int> keyBytes = utf8.encode(hashSecret);
    final List<int> dataBytes = utf8.encode(queryString);
    final hmac = Hmac(sha512, keyBytes);
    final String checkSum = hmac.convert(dataBytes).toString();

    // Đối chiếu hash tự tạo và hash do VNPay trả về
    return checkSum == vnpSecureHash;
  }
}
