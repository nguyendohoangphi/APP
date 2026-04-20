import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:coffeeapp/constants/app_colors.dart';
import 'package:coffeeapp/services/vnpay_service.dart';

class VNPayScreen extends StatefulWidget {
  final String paymentUrl;
  final bool isDark;

  const VNPayScreen({
    super.key,
    required this.paymentUrl,
    required this.isDark,
  });

  @override
  State<VNPayScreen> createState() => _VNPayScreenState();
}

class _VNPayScreenState extends State<VNPayScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Khi VNPay hoàn tất, nó sẽ gọi lại vnp_ReturnUrl mà chúng ta thiết lập
            if (request.url.contains('vnp_ResponseCode')) {
              _handleReturnUrl(request.url);
              return NavigationDecision.prevent; // Ngừng chuyển hướng
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handleReturnUrl(String url) {
    try {
      // Extract chuỗi query params gốc, bỏ qua quá trình parse tự động của Uri
      // Vì Uri.queryParameters sẽ tự động decode url dẫn đến sai lệch raw signature
      final queryStringIndex = url.indexOf('?');
      if (queryStringIndex == -1) {
        Navigator.of(context).pop(false);
        return;
      }

      final queryString = url.substring(queryStringIndex + 1);
      final splitParams = queryString.split('&');

      final Map<String, String> rawParams = {};
      for (var param in splitParams) {
        if (param.contains('=')) {
          final parts = param.split('=');
          rawParams[parts[0]] = parts[1]; // Giữ nguyên URI Encoded Format
        }
      }

      // Bước xác thực chữ ký để chống giả mạo URL giao dịch
      final responseCode = rawParams['vnp_ResponseCode'];
      final isValid = VNPayService.verifyChecksum(rawParams);

      if (isValid && responseCode == '00') {
        // Payment successful
        Navigator.of(context).pop(true);
      } else {
        // Payment failed, canceled, or checksum mismatch
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Thanh toán VNPay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Hủy thanh toán khi bấm nút back
            Navigator.of(context).pop(false);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
