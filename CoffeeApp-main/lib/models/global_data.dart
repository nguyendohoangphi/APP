import 'package:coffeeapp/models/cartitem.dart';
import 'package:coffeeapp/models/userdetail.dart';

class GlobalData {
  static List<CartItem> cartItemList = [];

  static UserDetail userDetail = UserDetail(
    uid: '',
    username: '',
    email: '',
    photoURL: 'assets/images/avatar/user.png',
    rank: 'Hạng đồng',
    point: 0,
    role: 'user',
    phone: '',
  );
}
