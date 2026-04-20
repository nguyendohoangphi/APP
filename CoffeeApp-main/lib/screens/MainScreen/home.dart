// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'dart:async';
import 'dart:ui';
import 'package:coffeeapp/constants/app_colors.dart';
import 'package:coffeeapp/models/ads.dart';
import 'package:coffeeapp/models/categoryproduct.dart';
import 'package:coffeeapp/models/global_data.dart';
import 'package:coffeeapp/models/product.dart';
import 'package:coffeeapp/models/productfavourite.dart';
import 'package:coffeeapp/screens/MainScreen/widgets/home_banner.dart';
import 'package:coffeeapp/screens/MainScreen/widgets/home_header.dart';
import 'package:coffeeapp/screens/chat_screen.dart';
import 'package:coffeeapp/screens/MainScreen/widgets/home_search_bar.dart';
import 'package:coffeeapp/screens/Product/product_list.dart';
import 'package:coffeeapp/services/firebase_db_manager.dart';
import 'package:coffeeapp/widgets/productcard_categorymain.dart';
import 'package:coffeeapp/widgets/productcard_recommended.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:coffeeapp/repositories/product_repository.dart';
import 'package:coffeeapp/repositories/auth_repository.dart';

class Home extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  const Home({required this.isDark, required this.onDarkChanged, super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late List<Product> productTop10HighRatingList = [];
  late List<Product> productsCategory = [];
  late List<CategoryProduct> categories = [];
  late List<Product> favouriteProduct = [];
  late List<Ads> ads = [];

  int indexCategory = 0;

  late Future<void> _loadDataFuture;
  final Logger logger = Logger();

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = LoadData();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refreshFavourites() async {
    List<ProductFavourite> favList = await FirebaseDBManager.favouriteService
        .getFavouritesByEmail(GlobalData.userDetail.email);

    List<Product> tempFav = [];
    final productRepo = context.read<IProductRepository>();

    for (var fav in favList) {
      // NOTE: Calling Repository in a loop is not ideal but maintaining logic structure for now.
      // Ideally should be a bulk lookup: getProductsByNames(List<String> names)
      tempFav.add(await productRepo.getProductByName(fav.productName));
    }

    if (mounted) {
      setState(() {
        favouriteProduct = tempFav;
      });
    }
  }

  Future<void> LoadData() async {
    // Usage AuthRepository
    final user = await context.read<IAuthRepository>().getProfile();
    if (user != null) {
      GlobalData.userDetail = user;
    }

    try {
      final productRepo = context.read<IProductRepository>();

      final results = await Future.wait([
        FirebaseDBManager.categoryProductService.getCategoryProductList(),
        productRepo.getTop10RatedProducts(),
        FirebaseDBManager.adsService.getAds(),
      ]);

      categories = results[0] as List<CategoryProduct>;
      productTop10HighRatingList = results[1] as List<Product>;
      ads = results[2] as List<Ads>;

      if (categories.isNotEmpty) {
        productsCategory = await productRepo.getProductsByType(
          categories[0].name,
        );
      }

      await _refreshFavourites();
    } catch (e) {
      logger.e("Error loading Home data", error: e);
    }
  }

  void _navigateToProductList(String keyword) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductList(
          nameProduct: keyword,
          productType: "",
          isDark: widget.isDark,
          index: 0,
        ),
      ),
    );
  }

  Future<void> _onCategorySelected(int index) async {
    setState(() => indexCategory = index);
    final products = await context.read<IProductRepository>().getProductsByType(
      categories[index].name,
    );
    setState(() {
      productsCategory = products;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? AppColors.cardDark.withOpacity(0.5)
                  : AppColors.espressoBrown.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Đã có lỗi xảy ra",
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _loadDataFuture = LoadData();
                      });
                    },
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeController,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeHeader(isDark: widget.isDark),
                        HomeSearchBar(
                          isDark: widget.isDark,
                          onProductSelected: _navigateToProductList,
                        ),
                        const SizedBox(height: 16),
                        HomeBanner(ads: ads, isDark: widget.isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: _buildCategoriesSection()),

                SliverToBoxAdapter(child: const SizedBox(height: 24)),

                SliverToBoxAdapter(child: _buildCategoryProductsList()),

                SliverToBoxAdapter(child: const SizedBox(height: 32)),

                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    "Đồ uống bán chạy",
                    'assets/video/CoffeeRecommended.json',
                  ),
                ),

                SliverToBoxAdapter(child: const SizedBox(height: 12)),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ProductcardRecommended(
                          product: productTop10HighRatingList[index],
                          isDark: widget.isDark,
                          index: index,
                          onFavoriteChanged: _refreshFavourites,
                        ),
                      );
                    }, childCount: productTop10HighRatingList.length),
                  ),
                ),

                SliverToBoxAdapter(child: const SizedBox(height: 24)),

                if (favouriteProduct.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      "Đồ uống yêu thích",
                      'assets/video/CoffeeFavourite.json',
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 12)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ProductcardRecommended(
                            product: favouriteProduct[index],
                            isDark: widget.isDark,
                            index: index,
                            onFavoriteChanged: _refreshFavourites,
                          ),
                        );
                      }, childCount: favouriteProduct.length),
                    ),
                  ),
                ],

                SliverToBoxAdapter(child: const SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Danh mục",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark
                      ? AppColors.textMainDark
                      : AppColors.espressoBrown,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductList(
                        nameProduct: "",
                        productType: categories[indexCategory].name,
                        isDark: widget.isDark,
                        index: 0,
                      ),
                    ),
                  );
                },
                child: Text(
                  "Xem tất cả",
                  style: TextStyle(
                    color: AppColors.warmGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 45,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              bool isSelected = indexCategory == index;
              return GestureDetector(
                onTap: () => _onCategorySelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.espressoBrown
                        : (widget.isDark
                              ? AppColors.cardDark
                              : AppColors.cream),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.espressoBrown.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      categories[index].displayName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (widget.isDark
                                  ? AppColors.textSubDark
                                  : AppColors.espressoBrown),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryProductsList() {
    if (productsCategory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text("Không có sản phẩm nào.")),
        ),
      );
    }

    return SizedBox(
      height: 245,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: productsCategory.length,
        separatorBuilder: (_, __) => const SizedBox(width: 0),
        itemBuilder: (context, index) {
          return ProductcardCategorymain(
            product: productsCategory[index],
            isDark: widget.isDark,
            index: index,
            onFavoriteChanged: _refreshFavourites,
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String lottieAsset) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(width: 40, height: 40, child: Lottie.asset(lottieAsset)),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDark
                  ? AppColors.textMainDark
                  : AppColors.espressoBrown,
            ),
          ),
        ],
      ),
    );
  }
}
