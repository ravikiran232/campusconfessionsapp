import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/confession_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled2/login_page.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/user_confession_page.dart';
import 'package:untitled2/user_provider.dart';
import 'models.dart' as Models;

class ShareServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createDynamicLink(String path, String documentid) async {
    final dynamiclinkparams = DynamicLinkParameters(
      link: Uri.parse("https://campusconfessions.page.link/$path/$documentid"),
      uriPrefix: "https://campusconfessions.page.link",
      androidParameters: const AndroidParameters(
          packageName: "com.gamingentertainment.iitkconfessions"),
    );
    try {
      final dynamiclink =
          await FirebaseDynamicLinks.instance.buildLink(dynamiclinkparams);
      return dynamiclink.normalizePath().toString();
    } catch (err) {
      return err.toString();
    }
  }

  void initDynamicLink(BuildContext context, RSAPublicKey? publicKey,
      RSAPrivateKey? privateKey) async {
    final instanceLink = await FirebaseDynamicLinks.instance
        .getInitialLink(); //returns null if app is not opened from dynamic link

    if (instanceLink != null) {
      if (_auth.currentUser == null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ),
        );
      } else {
        final Uri link = instanceLink.link;
        List pathfragments = link.path.split('/');
        if (pathfragments[1] == 'confessions') {
          DocumentSnapshot confessionSnapshot =
              await _firestore.collection('confessions').doc().get();
          Models.Confession confession = Models.Confession(
                  enablePoll: false,
                  poll: null,
                  notifyCountSIs: 0,
                  adminPost: false)
              .toConfessionModel(confessionSnapshot);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserConfessionPage(
                publicKey: publicKey,
                privateKey: privateKey,
                confession: confession,
                avatarURL: confession.avatarURL,
                firstTime: confession.views.contains(_auth.currentUser!.uid)
                    ? false
                    : true,
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> handleDynamicLink(BuildContext context, RSAPublicKey? publicKey,
      RSAPrivateKey? privateKey) async {
    FirebaseDynamicLinks.instance.onLink.listen(
      (event) async {
        if (_auth.currentUser == null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LoginPage(),
            ),
          );
        } else {
          List pathfragments = event.link.path.split("/");
          if (pathfragments[1] == "confessions") {
            DocumentSnapshot confessionSnapshot = await _firestore
                .collection('confessions')
                .doc(pathfragments[2])
                .get();
            Models.Confession confession = Models.Confession(
                    enablePoll: false,
                    poll: null,
                    notifyCountSIs: 0,
                    adminPost: false)
                .toConfessionModel(confessionSnapshot);
            Navigator.pushReplacement(
              context,
              PageTransition(
                child: ConfessionHomePage(),
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 50),
              ),
            );
            Navigator.push(
              context,
              PageTransition(
                child: UserConfessionPage(
                  publicKey: publicKey,
                  privateKey: privateKey,
                  confession: confession,
                  avatarURL: confession.avatarURL,
                  firstTime: confession.views.contains(_auth.currentUser!.uid)
                      ? false
                      : true,
                ),
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 50),
              ),
            );
          }
        }
      },
    );
  }
}
