// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';

import 'package:coffeeapp/models/product.dart';
import 'package:provider/provider.dart';
import 'package:coffeeapp/providers/cart_provider.dart';
import 'package:coffeeapp/models/cartitem.dart';
import 'package:coffeeapp/screens/Product/product_detail.dart';
import 'package:coffeeapp/constants/app_colors.dart';
import 'package:coffeeapp/constants/app_theme.dart';
import 'package:intl/intl.dart';

class ProductcardCategorymain extends StatefulWidget {
  final bool isDark;
  final int index;
  final Product product;
  final VoidCallback? onFavoriteChanged;

  const ProductcardCategorymain({
    super.key,
    required this.product,
    required this.isDark,
    required this.index,
    this.onFavoriteChanged,
  });

  @override
  State<ProductcardCategorymain> createState() =>
      _ProductcardCategorymainState();
}

class _ProductcardCategorymainState extends State<ProductcardCategorymain> {
  var format = NumberFormat.decimalPattern("vi_VN");

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = widget.isDark
        ? AppColors.textMainDark
        : AppColors.espressoBrown;
    final subColor = widget.isDark
        ? AppColors.textSubDark
        : AppColors.textSubLight;

    final imageBgColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : [
            AppColors.pastelOrange,
            AppColors.pastelGreen,
            AppColors.pastelBlue,
            AppColors.pastelPink,
          ][widget.index % 4];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetail(
              isDark: widget.isDark,
              index: 0,
              product: widget.product,
              onFavoriteChanged: widget.onFavoriteChanged,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),

          border: widget.isDark
              ? null
              : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: imageBgColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.borderRadius),
                      ),
                    ),
                    child: Hero(
                      tag: 'product_cat_${widget.product.name}_${widget.index}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImage(),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.product.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${format.format(widget.product.price)} đ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.espressoBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      InkWell(
                        onTap: _addToCart,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.espressoBrown,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.product.imageUrl.startsWith('http')) {
      return Image.network(widget.product.imageUrl, fit: BoxFit.contain);
    } else {
      return Image.asset(widget.product.imageUrl, fit: BoxFit.contain);
    }
  }

  void _addToCart() {
    setState(() {
      CartItem cartItem = CartItem(
        productName: widget.product.name,
        amount: 1,
        size: SizeOption.Small,
        idOrder: '',
        product: widget.product,
      );

      context.read<CartProvider>().addToCart(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã thêm ${widget.product.name} vào giỏ hàng"),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }
}
