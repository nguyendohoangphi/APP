  import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String baseUrl = "http://10.13.153.159:8000";
  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        // Decode utf8 to support Vietnamese
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'];
      } else {
        return "Lỗi máy chủ: ${response.statusCode}";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}
