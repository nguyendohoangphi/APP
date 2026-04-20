import 'package:coffeeapp/models/userdetail.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuthRepository {
  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<UserDetail?> getProfile({String? email});
  Future<void> updateUserPointAndRank(String email, int point, String rank);
  Future<void> saveUser(UserDetail user);
}
