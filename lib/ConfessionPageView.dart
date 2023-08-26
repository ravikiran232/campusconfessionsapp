import 'package:another_transformer_page_view/another_transformer_page_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:untitled2/firestore_methods.dart';
import 'package:untitled2/transformers.dart';
import 'package:untitled2/user_confession_page.dart';
import 'models.dart' as Models;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class ConfessionPageView extends StatefulWidget {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> confessions;
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  int currentIndex;
  ConfessionPageView({
    super.key,
    required this.publicKey,
    required this.privateKey,
    required this.confessions,
    required this.currentIndex,
  });

  @override
  State<ConfessionPageView> createState() => _ConfessionPageViewState();
}

class _ConfessionPageViewState extends State<ConfessionPageView> {
  final FirestoreMethods _firestoreMethods = FirestoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? confessionSharedKey;
  en.Encrypter? encrypter;

  bool refreshConfessionHomePage = false;

  @override
  Widget build(BuildContext context) {
    return TransformerPageView(
      onPageChanged: (value) async {
        if (!widget.confessions[value!]['views']
            .contains(_auth.currentUser!.uid)) {
          Models.Confession changedConfession = Models.Confession(
                  enablePoll: false,
                  poll: null,
                  notifyCountSIs: 0,
                  adminPost: false)
              .toConfessionModel(widget.confessions[value]);
          final en.Encrypter decrypter =
              en.Encrypter(en.RSA(privateKey: widget.privateKey));
          for (int i = 0;
              i < widget.confessions[value]['encryptedSharedKeys'].length;
              i++) {
            try {
              confessionSharedKey = decrypter.decrypt(en.Encrypted.fromBase64(
                  widget.confessions[value]['encryptedSharedKeys'][i]));
              encrypter =
                  en.Encrypter(en.AES(en.Key.fromBase64(confessionSharedKey!)));
            } catch (err) {}
          }
          await _firestoreMethods.viewedConfession(
              changedConfession, encrypter);
        }
      },
      index: widget.currentIndex,
      scrollDirection: Axis.horizontal,
      curve: Curves.easeInBack,
      transformer: transformers[3],
      itemCount: widget.confessions.length,
      itemBuilder: (context, index) {
        Models.Confession confession = Models.Confession(
                enablePoll: false,
                poll: null,
                notifyCountSIs: 0,
                adminPost: false)
            .toConfessionModel(widget.confessions[index]);
        if (confession.views.contains(_auth.currentUser!.uid) == false) {
          refreshConfessionHomePage = true;
        }
        return UserConfessionPage(
          publicKey: widget.publicKey,
          privateKey: widget.privateKey,
          confession: confession,
          avatarURL: confession.avatarURL,
          firstTime:
              confession.views.contains(_auth.currentUser!.uid) ? false : true,
          fromBeforePageView: refreshConfessionHomePage,
        );
      },
    );
  }
}
