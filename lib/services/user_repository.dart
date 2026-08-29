import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<UserModel> get _users => _firestore.collection('users').withConverter<UserModel>(
        fromFirestore: UserModel.fromFirestore,
        toFirestore: (user, _) => user.toFirestore(),
      );

  Stream<UserModel?> watchUser(String uid) =>
      _users.doc(uid).snapshots().map((snapshot) => snapshot.data());

  Future<void> createUser(UserModel user) => _users.doc(user.uid).set(user);

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) {
    return _firestore.collection('users').doc(uid).update({
      'name': name.trim(),
      'phone': phone.replaceAll(RegExp(r'\\D'), ''),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
