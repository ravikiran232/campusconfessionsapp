import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:untitled2/notification_services.dart';
import 'package:untitled2/storage_methods.dart';
import 'models.dart' as Models;

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageMethods _storageMethods = StorageMethods();

  final NotificationServices notificationServices = NotificationServices();

  Future<Models.User> getUserDetails(String user_uid) async {
    DocumentSnapshot snap =
        await _firestore.collection('users').doc(user_uid).get();
    Models.User user = Models.User(
        uid: user_uid,
        avatarURL: snap['avatarURL'],
        email: snap['email'],
        token: snap['token']);
    return user;
  }

  Future<String> LoginUser(String email, String password) async {
    email = email.trim();
    String res = 'Some error occurred.';
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      res = 'successfully logged in.';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> SignUpUser(
      String email, String password, Uint8List? avatar_data) async {
    String res = 'Some error occurred';
    try {
      email = email.trim();
      UserCredential user_creds = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      String avatarURL = 'default';
      avatar_data != null
          ? avatarURL = await _storageMethods.uploadImageToStorage(
              'Avatars', user_creds.user!.uid, avatar_data)
          : avatarURL = 'default';
      await _firestore.collection('users').doc(user_creds.user!.uid).set({
        'email': email,
        'uid': user_creds.user!.uid,
        'avatarURL': avatarURL,
        'token': await notificationServices.getDeviceToken()
      });
      res = 'successfully signed up!';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> logOutUser() async {
    String res = 'Some error occurred';
    try {
      await _auth.signOut();
      res = 'successfully logged out.';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }
}
