import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coffeeapp/models/userdetail.dart';
import 'package:coffeeapp/services/table_in_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    TableInDatabase.UserDetailTable,
  );

  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      await _users.doc(uid).set({
        "uid": uid,
        "username": username,
        "email": email,
        "photoURL": "assets/images/avatar/user.png",
        "rank": "Hạng đồng",
        "point": 0,
        "role": "user",
      });

      return "OK";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return "OK";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<UserDetail?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) return null;

    return UserDetail.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<List<UserDetail>> getAllUsers() async {
    final snapshot = await _users.get();
    return snapshot.docs
        .map((d) => UserDetail.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateUserPointAndRank(
    String uid,
    int point,
    String rank,
  ) async {
    await _users.doc(uid).set({
      "point": point,
      "rank": rank,
    }, SetOptions(merge: true));
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }

  Future<String> sendResetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Email khôi phục đã được gửi!";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Lỗi không xác định";
    }
  }
}
