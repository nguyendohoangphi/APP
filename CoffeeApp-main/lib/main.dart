import 'package:coffeeapp/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:coffeeapp/screens/SplashScreen/splashscreen.dart';

import 'package:coffeeapp/constants/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:coffeeapp/providers/user_provider.dart';
import 'package:coffeeapp/repositories/auth_repository.dart';
import 'package:coffeeapp/repositories/implementations/auth_repository_impl.dart';
import 'package:coffeeapp/repositories/product_repository.dart';
import 'package:coffeeapp/repositories/implementations/product_repository_impl.dart';
import 'package:coffeeapp/repositories/cart_repository.dart';
import 'package:coffeeapp/repositories/implementations/cart_repository_impl.dart';
import 'package:coffeeapp/providers/cart_provider.dart';
import 'package:coffeeapp/repositories/order_repository.dart';
import 'package:coffeeapp/repositories/implementations/order_repository_impl.dart';
import 'package:coffeeapp/repositories/revenue_repository.dart';
import 'package:coffeeapp/repositories/implementations/revenue_repository_impl.dart';
import 'package:coffeeapp/repositories/payment_repository.dart';
import 'package:coffeeapp/repositories/implementations/payment_repository_impl.dart';
import 'package:coffeeapp/repositories/coupon_repository.dart';
import 'package:coffeeapp/repositories/implementations/coupon_repository_impl.dart';
import 'package:coffeeapp/repositories/table_repository.dart';
import 'package:coffeeapp/repositories/implementations/table_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<IAuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<IProductRepository>(create: (_) => ProductRepositoryImpl()),
        Provider<ICartRepository>(create: (_) => CartRepositoryImpl()),
        Provider<IOrderRepository>(create: (_) => OrderRepositoryImpl()),
        Provider<IRevenueRepository>(create: (_) => RevenueRepositoryImpl()),
        Provider<ICouponRepository>(create: (_) => CouponRepositoryImpl()),
        Provider<ITableRepository>(create: (_) => TableRepositoryImpl()),
        ProxyProvider<IRevenueRepository, IPaymentRepository>(
          update: (context, revenueRepo, previous) =>
              PaymentRepositoryImpl(revenueRepo),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(
            authRepository: context.read<IAuthRepository>(),
            orderRepository: context.read<IOrderRepository>(),
            couponRepository: context.read<ICouponRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
