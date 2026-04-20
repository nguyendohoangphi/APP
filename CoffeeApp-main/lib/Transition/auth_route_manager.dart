import 'package:coffeeapp/Transition/menunavigationbar.dart';
import 'package:flutter/material.dart';

class AuthRouteManager {

  static void goToHome(BuildContext context, String role) {

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => _getDestination(role)),
      (Route<dynamic> route) => false,
    );
  }


  static Widget _getDestination(String role) {




    return const MenuNavigationBar(isDark: false, selectedIndex: 0);
  }
}
