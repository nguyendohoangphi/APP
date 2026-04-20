

// ignore_for_file: deprecated_member_use

import 'package:coffeeapp/constants/app_colors.dart';
import 'package:coffeeapp/constants/app_theme.dart';
import 'package:coffeeapp/models/cartitem.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.format,
    required this.isDark,
    required this.onIncrement,
    required this.onDecrement,
    required this.getSizeString,
  });

  final CartItem item;
  final NumberFormat format;
  final bool isDark;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String Function(SizeOption) getSizeString;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          AppColors.getShadow(isDark),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          Hero(
            tag: 'product_${item.product.name}_${item.size}_cart_${item.id}',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? Colors.grey[800] : AppColors.backgroundLight,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  item.product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.coffee,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                    fontSize: 16
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Size: ${getSizeString(item.size)}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${format.format(item.product.price)} đ',
                  style: TextStyle(
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          

          Container(
             decoration: BoxDecoration(
               color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
               borderRadius: BorderRadius.circular(12)
             ),
             padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
             child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuantityBtn(Icons.add_rounded, onIncrement, isDark, color: AppColors.success),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '${item.amount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                    ),
                  ),
                ),
                _buildQuantityBtn(Icons.remove_rounded, onDecrement, isDark, color: AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBtn(IconData icon, VoidCallback onTap, bool isDark, {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(4),
           child: Icon(
             icon,
             size: 20,
             color: color ?? (isDark ? AppColors.textMainDark : AppColors.textMainLight)
           ),
        ),
      ),
    );
  }
}
