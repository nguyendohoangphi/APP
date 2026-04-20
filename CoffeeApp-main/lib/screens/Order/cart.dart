// ignore_for_file: unnecessary_import, use_build_context_synchronously, deprecated_member_use

import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:coffeeapp/providers/cart_provider.dart';

import 'package:coffeeapp/repositories/cart_repository.dart';
import 'package:coffeeapp/repositories/auth_repository.dart';
import 'package:coffeeapp/repositories/order_repository.dart';
import 'package:coffeeapp/repositories/payment_repository.dart';
import 'package:coffeeapp/repositories/coupon_repository.dart';
import 'package:coffeeapp/repositories/table_repository.dart';
import 'package:coffeeapp/constants/app_colors.dart';

import 'package:flutter/material.dart';

import 'package:coffeeapp/models/cartitem.dart';
import 'package:coffeeapp/models/global_data.dart';

import 'package:coffeeapp/models/tablestatus.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class Cart extends StatefulWidget {
  final bool isDark;
  final int index;
  final bool isTab;

  const Cart({
    required this.isDark,
    super.key,
    required this.index,
    this.isTab = false,
  });

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final double tiencong = 10000;
  // final _paymentService = PaymentService(); // Removed in favor of Repository
  bool _isProcessing = false;

  final TextEditingController _controllerPhone = TextEditingController();
  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerDiscountCoupon =
      TextEditingController();
  String? _selectedTable = '';
  late List<TableStatus> _tableNumbers = [];

  @override
  void initState() {
    super.initState();

    _controllerName.text = GlobalData.userDetail.username;
    _controllerPhone.text = GlobalData.userDetail.phone ?? '';
  }

  final TextEditingController _controllerNote = TextEditingController();

  @override
  void dispose() {
    _controllerPhone.dispose();
    _controllerName.dispose();
    _controllerDiscountCoupon.dispose();
    _controllerNote.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    final cartProvider = context.read<CartProvider>();
    final cartItems = cartProvider.cartItems;

    if (_tableNumbers.isEmpty || _selectedTable!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hết bàn hoặc chưa chọn bàn')),
      );
      return;
    }
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có sản phẩm nào trong giỏ hàng')),
      );
      return;
    }
    if (_controllerName.text.isEmpty || _controllerPhone.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ thông tin')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      String tableId = _tableNumbers
          .firstWhere((t) => t.nameTable == _selectedTable)
          .id;

      bool success = await cartProvider.processCheckout(
        context: context,
        name: _controllerName.text,
        phone: _controllerPhone.text,
        note: _controllerNote.text,
        tableName: _selectedTable!,
        tableId: tableId,
        orderRepo: context.read<IOrderRepository>(),
        cartRepo: context.read<ICartRepository>(),
        paymentRepo: context.read<IPaymentRepository>(),
        tableRepo: context.read<ITableRepository>(),
        authRepo: context.read<IAuthRepository>(),
        couponRepo: context.read<ICouponRepository>(),
        userEmail: GlobalData.userDetail.email,
      );

      if (success) {
        setState(() {
          _controllerDiscountCoupon.text = '';
          _selectedTable = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt hàng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        if (!widget.isTab) {
          Navigator.of(context).pop();
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Thanh toán thất bại.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xảy ra lỗi: ${e.toString()}')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (_tableNumbers.isEmpty) {
      _tableNumbers = await context
          .read<ITableRepository>()
          .getTablesByBookingStatus(false);
    }
    final cartProvider = context.read<CartProvider>();
    if (cartProvider.availableCoupons.isEmpty) {
      await cartProvider.loadCoupons(
        context.read<ICouponRepository>(),
        GlobalData.userDetail.email,
      );
    }
  }

  String _getSizeString(SizeOption size) {
    switch (size) {
      case SizeOption.Small:
        return "Nhỏ";
      case SizeOption.Medium:
        return "Vừa";
      case SizeOption.Large:
        return "Lớn";
    }
  }

  @override
  Widget build(BuildContext context) {
    var format = NumberFormat("#,###", "vi_VN");
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.cartItems;

    late double subTotal = cartProvider.subTotal;
    late double discount = cartProvider.discountAmount;
    late double total = cartProvider.total;

    final Color textColor = widget.isDark
        ? AppColors.textMainDark
        : AppColors.textMainLight;
    final Color subTextColor = widget.isDark
        ? AppColors.textSubDark
        : AppColors.textSubLight;
    final Color cardColor = widget.isDark
        ? AppColors.cardDark
        : AppColors.cardLight;

    return Scaffold(
      backgroundColor: widget.isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: textColor),
              ),
        title: Text(
          "Giỏ hàng",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _loadData(),
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _tableNumbers.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Lỗi tải dữ liệu bàn và khuyến mãi:\n${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cartItems.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  "Không có gì trong giỏ hàng.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: subTextColor,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cartItems.length,
                              itemBuilder: (context, index) {
                                final item = cartItems[index];
                                return Slidable(
                                  key: ValueKey(
                                    item.product.name + item.size.toString(),
                                  ),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.33,
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Xác nhận xóa'),
                                              content: Text(
                                                'Bạn có chắc chắn muốn xóa "${item.product.name} - ${_getSizeString(item.size)}" khỏi giỏ hàng?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                                  child: const Text('Xóa'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true) {
                                            cartProvider.removeFromCart(item);
                                          }
                                        },
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'Xóa',
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.asset(
                                            item.product.imageUrl,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                              ),
                                              Text(
                                                _getSizeString(item.size),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: subTextColor,
                                                ),
                                              ),
                                              Text(
                                                '${format.format(item.product.price)} đ',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              color: subTextColor,
                                              onPressed: () {
                                                if (item.amount > 1) {
                                                  cartProvider.decrementItem(
                                                    item,
                                                  );
                                                }
                                              },
                                            ),
                                            Text(
                                              '${item.amount}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              color: AppColors.primary,
                                              onPressed: () {
                                                if (item.amount < 10) {
                                                  cartProvider.incrementItem(
                                                    item,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 24),

                      Text(
                        "Thông tin người đặt",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controllerName,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Nhập họ và tên",
                          labelText: "Họ và tên",
                          labelStyle: TextStyle(color: subTextColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controllerPhone,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Nhập số điện thoại",
                          labelText: "Số điện thoại",
                          labelStyle: TextStyle(color: subTextColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedTable,
                        dropdownColor: cardColor,
                        style: TextStyle(color: textColor),
                        onChanged: (String? newValue) =>
                            setState(() => _selectedTable = newValue!),
                        items: [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text(
                              "--Chọn bàn--",
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          ..._tableNumbers.map(
                            (TableStatus value) => DropdownMenuItem<String>(
                              value: value.nameTable,
                              child: Text(
                                value.nameTable,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: "Bàn",
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.table_bar_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controllerNote,
                        style: TextStyle(color: textColor),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: "Ghi chú (ít đường, ít đá...)",
                          labelText: "Ghi chú",
                          labelStyle: TextStyle(color: subTextColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.note_alt_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "Khuyến mãi & Hóa đơn",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controllerDiscountCoupon,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Nhập mã giảm giá",
                          labelText: "Mã giảm giá",
                          labelStyle: TextStyle(color: subTextColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.card_giftcard,
                            color: AppColors.primary,
                          ),
                          suffixIcon: TextButton(
                            onPressed: () {
                              if (cartProvider.availableCoupons.containsKey(
                                _controllerDiscountCoupon.text,
                              )) {
                                cartProvider.applyCoupon(
                                  _controllerDiscountCoupon.text,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mã không hợp lệ'),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Áp dụng',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tạm tính:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: subTextColor,
                                  ),
                                ),
                                Text(
                                  '${format.format(subTotal)} đ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tiền công:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: subTextColor,
                                  ),
                                ),
                                Text(
                                  '${format.format(tiencong)} đ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Giảm giá:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: subTextColor,
                                  ),
                                ),
                                Text(
                                  '- ${format.format(discount)} đ',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tổng cộng:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  '${format.format(total)} đ',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.cardDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (_isProcessing || cartProvider.cartItems.isEmpty)
                      ? null
                      : () => _processCheckout(),
                  icon: _isProcessing
                      ? const SizedBox.shrink()
                      : const Icon(Icons.shield_outlined),
                  label: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Thanh toán an toàn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
