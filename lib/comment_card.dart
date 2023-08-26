import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled2/comment_clipper.dart';
import 'package:untitled2/firestore_methods.dart';
import 'package:untitled2/models.dart';
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class CommentCard extends StatefulWidget {
  en.Encrypter? encrypter;
  RSAPrivateKey privateKey;
  Comment comment;
  bool disableEverything;
  bool isOwner;
  CommentCard(
      {super.key,
      required this.encrypter,
      required this.privateKey,
      required this.comment,
      required this.isOwner,
      this.disableEverything = false});

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 0.0,
        vertical: 10.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 6.0,
              top: 12.0,
              bottom: 20.0,
            ),
            child: CircleAvatar(
              radius: 14.0,
              backgroundColor: Colors.black,
              child: widget.comment.avatarURL == 'default'
                  ? const CircleAvatar(
                      radius: 13.0,
                      backgroundImage:
                          AssetImage('assets/images/default_avatar.jpg'),
                    )
                  : CircleAvatar(
                      radius: 13.0,
                      backgroundImage: NetworkImage(widget.comment.avatarURL!),
                    ),
            ),
          ),
          CommentClipper(
            encrypter: widget.encrypter, //here is the error
            privateKey: widget.privateKey,
            comment: widget.comment,
            disableEverything: widget.disableEverything,
            isOwner: widget.isOwner,
          ),
        ],
      ),
    );
  }
}
