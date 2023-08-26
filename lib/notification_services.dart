import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:untitled2/AdminPage.dart';
import 'package:untitled2/confession_home_page.dart';
import 'package:untitled2/firestore_methods.dart';
import 'package:untitled2/user_confession_page.dart';
import 'models.dart' as Models;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:http/http.dart' as http;

class NotificationServices {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreMethods _firestoreMethods = FirestoreMethods();

  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
    } else {
      AppSettings.openNotificationSettings();
    }
  }

  Future<String> getDeviceToken() async {
    try {
      String? token = await messaging.getToken();
      return token!;
    } catch (e) {
      return 'Undefined';
    }
  }

  void refreshToken(BuildContext context) async {
    messaging.onTokenRefresh.listen((newToken) async {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'token': newToken.toString()});
    });
  }

  void initLocalNotifications(
      BuildContext context,
      RemoteMessage message,
      RSAPublicKey? publicKey,
      RSAPrivateKey? privateKey,
      List<dynamic> admins,
      String primaryAdmin) async {
    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings iOSInitializationSettings =
        const DarwinInitializationSettings();

    InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings, iOS: iOSInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (payload) {
      handleMessage(
        context,
        message,
        publicKey,
        privateKey,
        admins,
        primaryAdmin,
      );
    });
  }

  void firebaseInit(
    BuildContext context,
    RSAPublicKey? publicKey,
    RSAPrivateKey? privateKey,
    List<dynamic> admins,
    String primaryAdmin,
  ) {
    FirebaseMessaging.onMessage.listen((message) {
      if (Platform.isAndroid) {
        initLocalNotifications(
            context, message, publicKey, privateKey, admins, primaryAdmin);
      }
      showNotification(message);
    });
  }

  Future<void> setupInteractMessage(
    BuildContext context,
    RSAPublicKey? publicKey,
    RSAPrivateKey? privateKey,
    List<dynamic> admins,
    String primaryAdmin,
  ) async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      handleMessage(
        context,
        initialMessage,
        publicKey,
        privateKey,
        admins,
        primaryAdmin,
      );
    }

    FirebaseMessaging.onMessageOpenedApp.listen(
      (event) {
        handleMessage(
          context,
          event,
          publicKey,
          privateKey,
          admins,
          primaryAdmin,
        );
      },
    );
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(Random.secure().nextInt(1000).toString(),
            'High Importance Notifications',
            importance: Importance.max, playSound: true);

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(androidNotificationChannel.id.toString(),
            androidNotificationChannel.name.toString(),
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker');

    DarwinNotificationDetails iOSNotificationDetails =
        const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true);

    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: iOSNotificationDetails);

    String title = message.data['title'] ?? '';
    String body = message.data['body'] ?? '';

    await Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
          0, title, body, notificationDetails);
    });
  }

  void handleMessage(
    BuildContext context,
    RemoteMessage message,
    RSAPublicKey? publicKey,
    RSAPrivateKey? privateKey,
    List<dynamic> admins,
    String primaryAdmin,
  ) async {
    try {
      if (message.data['type'] == 'confession' ||
          message.data['type'] == 'toSpecificIndividual') {
        Map<String, dynamic> decodedConfession =
            jsonDecode(message.data['confession']);
        DocumentSnapshot confessionSnap = await _firestore
            .collection('confessions')
            .doc(decodedConfession['confessionId'])
            .get();
        Models.Confession confessionFromJSON = Models.Confession(
            user_uid: decodedConfession['user_uid'],
            confessionId: decodedConfession['confessionId'],
            confession_no: decodedConfession['confession_no'],
            confession: decodedConfession['confession'],
            avatarURL: decodedConfession['avatarURL'],
            enableAnonymousChat: decodedConfession['enableAnonymousChat'],
            enableSpecificIndividuals:
                decodedConfession['enableSpecificIndividuals'],
            specificIndividuals: decodedConfession['specificIndividuals'],
            seenBySIs: confessionSnap['seenBySIs'],
            views: confessionSnap['views'],
            upvotes: confessionSnap['upvotes'],
            downvotes: confessionSnap['downvotes'],
            reactions: confessionSnap['reactions'],
            datePublished: Timestamp.fromDate(
                DateTime.parse(decodedConfession['datePublished'])),
            enablePoll: confessionSnap['enablePoll'],
            poll: confessionSnap['poll'],
            encryptedSharedKeys: decodedConfession['encryptedSharedKeys'],
            notifyCountSIs: decodedConfession['notifyCountSIs'],
            adminPost: decodedConfession['adminPost']);
        // Navigator.push(
        //   context,
        //   CupertinoPageRoute(
        //     builder: (context) => UserConfessionPage(
        //       publicKey: publicKey,
        //       privateKey: privateKey,
        //       confession: confessionFromJSON,
        //       avatarURL: confessionFromJSON.avatarURL,
        //       firstTime:
        //           confessionFromJSON.views.contains(_auth.currentUser!.uid)
        //               ? false
        //               : true,
        //     ),
        //   ),
        // );
        UserConfessionPage(
            publicKey: publicKey,
            privateKey: privateKey,
            confession: confessionFromJSON,
            avatarURL: confessionFromJSON.avatarURL,
            firstTime: confessionFromJSON.views.contains(_auth.currentUser!.uid)
                ? false
                : true);
        en.Encrypter? encrypter;
        String? confessionSharedKey;
        final en.Encrypter decrypter =
            en.Encrypter(en.RSA(privateKey: privateKey));
        for (int i = 0;
            i < confessionFromJSON.encryptedSharedKeys!.length;
            i++) {
          try {
            confessionSharedKey = decrypter.decrypt(en.Encrypted.fromBase64(
                confessionFromJSON.encryptedSharedKeys![i]));
            encrypter =
                en.Encrypter(en.AES(en.Key.fromBase64(confessionSharedKey!)));
          } catch (err) {}
        }
        await _firestoreMethods.viewedConfession(confessionFromJSON, encrypter);
        if (message.data['type'] == 'toSpecificIndividual') {
          DocumentSnapshot<Map<String, dynamic>> confessionOwnerDocSnap =
              await _firestore
                  .collection('users')
                  .doc(encrypter!.decrypt(
                      en.Encrypted.fromBase64(confessionFromJSON.user_uid),
                      iv: en.IV.fromBase64('campus12')))
                  .get();
          String ownerToken = confessionOwnerDocSnap['token'];
          Map<dynamic, dynamic> data = {
            'to': ownerToken,
            'priority': 'high',
            'data': {
              'title': 'Confessions',
              'body': "A specific individual viewed your confession!",
              'type': 'viewedConfession',
            }
          };
          await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
              body: jsonEncode(data),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization':
                    'key=AAAAtA6V0JA:APA91bEwrE_GBMBe-aWVap09EcR0H9peWaMIY3nM9ewzsxCxjYL9gbBuGPIIPvs-jStFGTMnFI6cq7Lw_bH3yaRuuwymAVppZO1Y6fGI45QgscvFzEfYXHIrn9on6b68y1F59Jg6KweO'
              });
        }
      } else if (message.data['type'] == 'viewedConfession') {
        Map<String, dynamic> decodedConfession =
            jsonDecode(message.data['confession']);
        DocumentSnapshot confessionSnap = await _firestore
            .collection('confessions')
            .doc(decodedConfession['confessionId'])
            .get();
        Models.Confession confessionFromJSON = Models.Confession(
            user_uid: decodedConfession['user_uid'],
            confessionId: decodedConfession['confessionId'],
            confession_no: decodedConfession['confession_no'],
            confession: decodedConfession['confession'],
            avatarURL: decodedConfession['avatarURL'],
            enableAnonymousChat: decodedConfession['enableAnonymousChat'],
            enableSpecificIndividuals:
                decodedConfession['enableSpecificIndividuals'],
            specificIndividuals: decodedConfession['specificIndividuals'],
            seenBySIs: confessionSnap['seenBySIs'],
            views: confessionSnap['views'],
            upvotes: confessionSnap['upvotes'],
            downvotes: confessionSnap['downvotes'],
            reactions: confessionSnap['reactions'],
            datePublished: Timestamp.fromDate(
                DateTime.parse(decodedConfession['datePublished'])),
            enablePoll: confessionSnap['enablePoll'],
            poll: confessionSnap['poll'],
            encryptedSharedKeys: decodedConfession['encryptedSharedKeys'],
            notifyCountSIs: decodedConfession['notifyCountSIs'],
            adminPost: decodedConfession['adminPost']);
        // Navigator.push(
        //   context,
        //   CupertinoPageRoute(
        //     builder: (context) => UserConfessionPage(
        //       publicKey: publicKey,
        //       privateKey: privateKey,
        //       confession: confessionFromJSON,
        //       avatarURL: confessionFromJSON.avatarURL,
        //       firstTime:
        //           confessionFromJSON.views.contains(_auth.currentUser!.uid)
        //               ? false
        //               : true,
        //     ),
        //   ),
        // );
        UserConfessionPage(
            publicKey: publicKey,
            privateKey: privateKey,
            confession: confessionFromJSON,
            avatarURL: confessionFromJSON.avatarURL,
            firstTime: confessionFromJSON.views.contains(_auth.currentUser!.uid)
                ? false
                : true);
      } else if (message.data['type'] == 'admin approval') {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => ConfessionHomePage(),
          ),
        );
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => AdminPage(
              publicKey: publicKey!,
              privateKey: privateKey!,
              admins: admins,
              primaryAdmin: primaryAdmin,
            ),
          ),
        );
      }
    } catch (e) {}
  }
}
