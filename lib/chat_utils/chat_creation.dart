import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

//for creating a chatroom id;
createchatroomid(useruid, distantuid, en.Encrypter encrypter) async {
  String roomid = const Uuid().v4();

  Map<String, dynamic> data = {
    "status": {
      "${encrypter.encrypt(useruid, iv: en.IV.fromBase64('campus12')).base64}":
          "offline",
      "${encrypter.encrypt(distantuid, iv: en.IV.fromBase64('campus12')).base64}":
          "offline"
    },
    "typing": {
      "${encrypter.encrypt(useruid, iv: en.IV.fromBase64('campus12')).base64}":
          false,
      "${encrypter.encrypt(distantuid, iv: en.IV.fromBase64('campus12')).base64}":
          false
    },
    "endchat": false
  };

  try {
    await FirebaseFirestore.instance
        .collection("chatdata")
        .doc(roomid)
        .set(data);
    return roomid;
  } on FirebaseException catch (e) {
    Fluttertoast.showToast(
      msg: "something went wrong ${e.message}",
      textColor: Colors.white,
      backgroundColor: const Color.fromARGB(211, 0, 0, 0),
    );
    return 'Some error occurred';
  } on Exception catch (e) {
    Fluttertoast.showToast(
      msg: "Something went wrong",
      textColor: Colors.white,
      backgroundColor: const Color.fromARGB(211, 0, 0, 0),
    );
    return 'Some error occurred';
  }
}
