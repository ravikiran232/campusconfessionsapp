import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled2/auth_methods.dart';
import 'models.dart' as Models;

class UserProvider with ChangeNotifier {
  Models.User? _user;
  final AuthMethods _authMethods = AuthMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Models.User? get getUser => _user;

  Future<void> refreshUser() async {
    Models.User user =
        await _authMethods.getUserDetails(_auth.currentUser!.uid);
    _user = user;
    notifyListeners();
  }
}
