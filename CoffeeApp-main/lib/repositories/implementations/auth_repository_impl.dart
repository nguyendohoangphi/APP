// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coffeeapp/models/userdetail.dart';
import 'package:coffeeapp/repositories/auth_repository.dart';
import 'package:coffeeapp/services/table_in_database.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    TableInDatabase.UserDetailTable,
  );

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return cred.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<User?> signUp(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<UserDetail?> getProfile({String? email}) async {
    if (email != null) {
    }

    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _users.doc(user.uid).get();

    if (!doc.exists && email != null) {
    }

    if (doc.exists) {
      return UserDetail.fromJson(doc.data() as Map<String, dynamic>);
    }

    return null;
  }

  @override
  Future<void> saveUser(UserDetail user) async {
    await _users.doc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateUserPointAndRank(
    String email,
    int point,
    String rank,
  ) async {
    try {
      final query = await _users
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({"point": point, "rank": rank});
      } else {
        await _users
            .doc(email)
            .update({"point": point, "rank": rank})
            .catchError((e) => print("Update failed: $e"));
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
