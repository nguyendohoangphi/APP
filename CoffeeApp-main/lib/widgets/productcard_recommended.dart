// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:coffeeapp/utils/executeratingdisplay.dart';
import 'package:coffeeapp/models/product.dart';
import 'package:provider/provider.dart';
import 'package:coffeeapp/providers/cart_provider.dart';
import 'package:coffeeapp/models/cartitem.dart';
import 'package:coffeeapp/screens/Product/product_detail.dart';
import 'package:coffeeapp/constants/app_colors.dart';
import 'package:coffeeapp/constants/app_theme.dart';
import 'package:intl/intl.dart';

class ProductcardRecommended extends StatefulWidget {
  final bool isDark;
  final int index;
  final Product product;
  final VoidCallback? onFavoriteChanged;

  ProductcardRecommended({
    super.key,
    required this.product,
    required this.isDark,
    required this.index,
    this.onFavoriteChanged,
  });

  @override
  State<ProductcardRecommended> createState() => _ProductcardRecommendedState();
}

class _ProductcardRecommendedState extends State<ProductcardRecommended> {
  final format = NumberFormat("#,###", "vi_VN");

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.cardDark : Colors.white;
    final titleColor = widget.isDark
        ? AppColors.textMainDark
        : AppColors.espressoBrown;
    final subColor = widget.isDark
        ? AppColors.textSubDark
        : AppColors.textSubLight;

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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: [AppColors.getShadow(widget.isDark)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product_img_${widget.product.name}_${widget.index}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.isDark
                      ? Colors.grey[800]
                      : AppColors.backgroundLight,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildProductImage(widget.product.imageUrl),
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: SizedBox(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: titleColor,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Executeratingdisplay(
                              rate: widget.product.rating,
                              itemSize: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${widget.product.reviewCount})',
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: format.format(widget.product.price),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.espressoBrown,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextSpan(
                                text: ' đ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.espressoBrown.withOpacity(
                                    0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Material(
                          color: AppColors.espressoBrown,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _addToCart,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.espressoBrown.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.hub, color: Colors.grey),
      );
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

      // CartProvider handles checking duplicates and incrementing
      context.read<CartProvider>().addToCart(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Added ${widget.product.name} to cart!",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    });
  }
}
