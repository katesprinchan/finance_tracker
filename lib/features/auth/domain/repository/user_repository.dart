import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/features/auth/data/source/user_model.dart';
import 'package:finance_tracker/features/auth/presentation/snack_bar.dart';
import 'package:flutter/material.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;
  final BuildContext context;

  UserRepository(this.context);

  Future<void> createUser(String uid, UserModel user) async {
    try {
      await _db.collection("Users").doc(uid).set(user.toJson());
    } catch (error) {
      print("Error adding user: $error");
      SnackBarService.showSnackBar(
        context,
        S.of(context).unknownError,
        true,
      );
    }
  }
}
