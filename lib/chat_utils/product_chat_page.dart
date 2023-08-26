import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:provider/provider.dart';
import '../firestore_methods.dart';
import '../user_provider.dart';
import 'firebase_options.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:read_more_text/read_more_text.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_database/firebase_database.dart';
import 'sql_queries.dart';
import 'package:untitled2/models.dart' as Models;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:http/http.dart' as http;

class Chatt extends StatelessWidget {
  RSAPrivateKey currentUserPrivateKey;
  RSAPublicKey distantUserPublicKey;
  en.Encrypter sharedKeyEncrypter;
  Models.Confession confession;
  Chatt(
      {super.key,
      required this.documentid,
      required this.uid,
      required this.distantuid,
      required this.confession,
      required this.currentUserPrivateKey,
      required this.distantUserPublicKey,
      required this.sharedKeyEncrypter,
      required this.avatarURL});
  final String documentid;
  final String uid;
  final String distantuid;
  final String avatarURL;
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return MaterialApp(
        home: Chatpage(
      currentUserPrivateKey: currentUserPrivateKey,
      distantUserPublicKey: distantUserPublicKey,
      sharedKeyEncrypter: sharedKeyEncrypter,
      documentid: documentid,
      width: width,
      distantuid: distantuid,
      uid: uid,
      avatarURL: avatarURL,
      confession: confession,
    ));
  }
}

class Chatpage extends StatefulWidget {
  RSAPrivateKey currentUserPrivateKey;
  RSAPublicKey distantUserPublicKey;
  en.Encrypter sharedKeyEncrypter;
  final Function? delete;
  Models.Confession confession;
  Chatpage(
      {super.key,
      required this.avatarURL,
      required this.documentid,
      required this.confession,
      required this.currentUserPrivateKey,
      required this.distantUserPublicKey,
      required this.sharedKeyEncrypter,
      required this.width,
      this.delete,
      required this.uid,
      required this.distantuid});
  final String documentid;
  final String uid;
  final String distantuid;
  final double width;
  final String avatarURL;
  @override
  State<Chatpage> createState() => _Chatpage();
}

class _Chatpage extends State<Chatpage> with WidgetsBindingObserver {
  List<types.Message> _messages = [];
  bool _islaoding = false;
  bool toolbar = false;
  String uid = FirebaseAuth.instance.currentUser!.uid;
  final _user = types.User(id: FirebaseAuth.instance.currentUser!.uid);
  DatabaseReference ref = FirebaseDatabase.instance.ref("buyandsellmessages/");
  String status = "offline";
  bool chatended = false;
  List deleteoption = [];
  int? widgetcode;
  Map messageids = {};
  var notificationtoken;
  late StreamSubscription rd;
  late StreamSubscription notification;
  late StreamSubscription statusstream;
  late StreamSubscription deletemessage;
  late StreamSubscription token;
  late StreamSubscription endchatstream;

  en.Encrypter? encrypter;
  en.Encrypter? decrypter;

  @override
  void dispose() {
    rd.cancel();
    notification.cancel();
    statusstream.cancel();
    userstatus('offline');
    token.cancel();
    endchatstream.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState lifecycleState,
  ) {
    super.didChangeAppLifecycleState(lifecycleState);
    if (lifecycleState != AppLifecycleState.resumed) {
      userstatus("offline");
      if (!(rd.isPaused)) {
        rd.pause();
      }
    }
    if (lifecycleState == AppLifecycleState.resumed) {
      userstatus("online");
      if (rd.isPaused) {
        rd.resume();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    encrypter = en.Encrypter(en.RSA(publicKey: widget.distantUserPublicKey));
    decrypter = en.Encrypter(en.RSA(privateKey: widget.currentUserPrivateKey));
    WidgetsBinding.instance.addObserver(this);
    endchatstream = FirebaseFirestore.instance
        .collection("chatdata")
        .doc(widget.documentid)
        .snapshots()
        .listen((value) {
      if (value.exists) {
        setState(
          () => chatended = value.data()!["endchat"],
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      DocumentSnapshot<Map<String, dynamic>> chatDocSnap =
          await FirebaseFirestore.instance
              .collection('chatdata')
              .doc(widget.documentid)
              .get();
      Map<String, dynamic> chatStatus = chatDocSnap['status'];
      chatStatus[widget.sharedKeyEncrypter
          .encrypt(uid, iv: en.IV.fromBase64('campus12'))
          .base64] = 'online';
      FirebaseFirestore.instance
          .collection("chatdata")
          .doc(widget.documentid)
          .update({'status': chatStatus});
    });
    token = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.distantuid)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        notificationtoken = event.data()!["token"];
      }
    });
    notification =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {});
    statusstream = FirebaseFirestore.instance
        .collection("chatdata")
        .doc(widget.documentid)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        setState(() {
          status = event.data()!["status"][widget.sharedKeyEncrypter
              .encrypt(widget.distantuid, iv: en.IV.fromBase64('campus12'))
              .base64];
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<types.Message> dummymessagevariable =
          await loadingmessages(widget.documentid);
      if (dummymessagevariable.isNotEmpty) {
        setState(() {
          _messages.addAll(dummymessagevariable);
          _islaoding = false;
        });
      }
      rd = ref
          .child("${widget.documentid}/latsmessage")
          .orderByChild("/createdAt")
          .onValue
          .listen((event) async {
        readmessages(
          event,
        );
      });
      deletemessage = ref
          .child("${widget.documentid}/deletemessages")
          .onValue
          .listen((event) {
        if (event.snapshot.exists) {
          // List array = [];
          if (event.snapshot.value != null) {
            Map map_ids = event.snapshot.value as Map;
            List ids = map_ids.keys.toList();
            for (String message_ids in ids) {
              int index = _messages
                  .indexWhere((element) => (element.id == message_ids));
              if (index != -1) {
                setState(() {
                  _messages.removeAt(index);
                });
                ref
                    .child("${widget.documentid}/deletemessages/${message_ids}")
                    .remove();
              }
            }
            updatingmessages(jsonEncode(_messages), widget.documentid);
          }
          // if (array.isNotEmpty) {
          //   for (int i = 0; i < array.length; i++) {
          //     int index =
          //         _messages.indexWhere((element) => (element.id == array[i]));
          //     if (index != -1) {
          //       setState(() {
          //         _messages.removeAt(index);
          //       });
          //       ref
          //           .child(
          //               "${widget.documentid}/deletemessage/${widget.distantuid}/ids/$i")
          //           .remove();
          //     }
          //   }
          //   updatingmessages(jsonEncode(_messages), widget.documentid);
          // }
        }
      });
    });
    Future.delayed(
      const Duration(seconds: 2),
      () => Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg:
            'Uncomfortable? End the chat anytime from the menu. Your safety, your control.',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      ),
    );
  }

  readinitialmessages(DataSnapshot event) async {
    if (event.exists) {
      final map = event.value as Map;
      for (var value in map.entries) {
        bool isNotUser = false;
        String? text;
        try {
          text =
              decrypter!.decrypt(en.Encrypted.fromBase64(value.value['text']));
        } catch (err) {
          isNotUser = true;
        }
        if (!isNotUser & (value.value["status"] != "read")) {
          setState(() {
            _messages.insert(
                0,
                types.TextMessage(
                    id: value.key,
                    author: types.User(id: value.value["author"]),
                    createdAt: value.value["createdAt"],
                    text: text!));
          });
          await ref
              .child("${widget.documentid}/latsmessage/${value.key}/")
              .update({"status": "read"});
          // await ref
          //     .child("${widget.documentid}/messages/${value.key}/")
          //     .update({"status": "read"});
        }
        if (isNotUser) {
          var index = null;
          var updatedMessage;
          if (value.value["status"] == "sent") {
            try {
              index =
                  _messages.indexWhere((element) => element.id == value.key);
              if (index != -1) {
                updatedMessage = (_messages[index] as types.TextMessage)
                    .copyWith(status: types.Status.sent);
              }
            } on Exception catch (err) {}
          }
          if (value.value["status"] == "delivered") {
            try {
              index =
                  _messages.indexWhere((element) => element.id == value.key);
              updatedMessage = (_messages[index] as types.TextMessage)
                  .copyWith(status: types.Status.delivered);
            } on Exception catch (err) {}
          }
          if (value.value["status"] == "read") {
            try {
              index =
                  _messages.indexWhere((element) => element.id == value.key);
              if (index != -1) {
                updatedMessage = (_messages[index] as types.TextMessage)
                    .copyWith(status: types.Status.seen);
              }
            } on Exception catch (rr) {
              Fluttertoast.showToast(
                msg: rr.toString(),
                textColor: Colors.white,
                backgroundColor: const Color.fromARGB(211, 0, 0, 0),
              );
            }
            ;
            await ref
                .child("${widget.documentid}/latsmessage/${value.key}")
                .remove();
          }
          if ((index != null) & (index != -1)) {
            setState(() {
              _messages[index] = updatedMessage;
            });
          }
        }
      }
    }
    await updatingmessages(jsonEncode(_messages), widget.documentid);
  }

  readmessages(DatabaseEvent event) async {
    if (event.snapshot.exists) {
      final map = event.snapshot.value as Map;
      List<MapEntry> entries = map.entries.toList();
      entries
          .sort((a, b) => a.value['createdAt'].compareTo(b.value['createdAt']));
      for (var value in entries) {
        bool isNotUser = false;
        String text = "";
        try {
          // text =
          //     decrypter!.decrypt(en.Encrypted.fromBase64(value.value['text']));
          for (String text_part in value.value['text']) {
            text += decrypter!.decrypt(en.Encrypted.fromBase64(text_part));
          }
        } catch (err) {
          isNotUser = true;
        }
        if (!isNotUser & (value.value["status"] != "read")) {
          int existingIndex =
              _messages.indexWhere((element) => element.id == value.key);
          if (existingIndex == -1) {
            setState(() {
              _messages.insert(
                  0,
                  types.TextMessage(
                      id: value.key,
                      author: types.User(id: value.value["author"]),
                      createdAt: value.value["createdAt"],
                      text: text!));
            });
            await ref
                .child("${widget.documentid}/latsmessage/${value.key}/")
                .update({"status": "read"});
          }
        }
        if (isNotUser) {
          var index = null;
          var updatedMessage;
          if (value.value["status"] == "sent") {
            try {
              index =
                  _messages.indexWhere((element) => element.id == value.key);
              if (index != -1) {
                updatedMessage = (_messages[index] as types.TextMessage)
                    .copyWith(status: types.Status.sent);
              }
              ;
            } on Exception catch (err) {}
          }
          if (value.value["status"] == "delivered") {
            try {
              index =
                  _messages.indexWhere((element) => element.id == value.key);
              updatedMessage = (_messages[index] as types.TextMessage)
                  .copyWith(status: types.Status.delivered);
            } on Exception catch (err) {}
          }
          if (value.value["status"] == "read") {
            try {
              index =
                  _messages.indexWhere((element) => element.id == value.key);
              if (index != -1) {
                updatedMessage = (_messages[index] as types.TextMessage)
                    .copyWith(status: types.Status.seen);
              }
            } on Exception catch (rr) {
              Fluttertoast.showToast(
                msg: rr.toString(),
                textColor: Colors.white,
                backgroundColor: const Color.fromARGB(211, 0, 0, 0),
              );
            }
            await ref
                .child("${widget.documentid}/latsmessage/${value.key}")
                .remove();
          }
          if ((index != null) & (index != -1)) {
            setState(() {
              _messages[index] = updatedMessage;
            });
          }
        }
      }
    }
    await updatingmessages(jsonEncode(_messages), widget.documentid);
  }

  userstatus(String status__) async {
    DocumentSnapshot<Map<String, dynamic>> chatDocSnap = await FirebaseFirestore
        .instance
        .collection('chatdata')
        .doc(widget.documentid)
        .get();
    Map<String, dynamic> chatStatus = chatDocSnap['status'];
    chatStatus[widget.sharedKeyEncrypter
        .encrypt(uid, iv: en.IV.fromBase64('campus12'))
        .base64] = status__;
    await FirebaseFirestore.instance
        .collection("chatdata")
        .doc(widget.documentid)
        .update({'status': chatStatus});
  }

  keyboardlistner(String message) async {}

  List messagescopy(List<types.Message> messageslist, Map messageids) {
    List copymessages = [];
    for (String value in messageids.keys) {
      try {
        int index = _messages.indexWhere((element) => element.id == value);
        types.TextMessage singlemessage = _messages[index] as types.TextMessage;
        copymessages.add(
            "${singlemessage.text}  [${DateTime.fromMillisecondsSinceEpoch(singlemessage.createdAt!)}]");
      } on Exception catch (err) {
        Fluttertoast.showToast(
          msg: err.toString(),
          textColor: Colors.white,
          backgroundColor: const Color.fromARGB(211, 0, 0, 0),
        );
      }
    }
    return copymessages;
  }

  addmessages(message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void messagelongpress(types.Message message) {
    if (messageids.isEmpty) {
      setState(() {
        messageids.addAll({message.id: message.author == _user});
        toolbar = !toolbar;
      });
    }
  }

  void messagetap(types.Message message) {
    if (toolbar) {
      if (messageids.containsKey(message.id)) {
        setState(() {
          messageids.remove(message.id);
        });
        if (messageids.isEmpty) {
          setState(() {
            toolbar = !toolbar;
          });
        }
      } else {
        setState(() {
          messageids.addAll({message.id: message.author == _user});
        });
      }
    }
  }

  deletedialog(BuildContext _) async {
    return showDialog(
      context: _,
      builder: (_) => Card(
        margin: EdgeInsets.symmetric(
            horizontal: 70.0, vertical: MediaQuery.of(_).size.height * 0.40),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () async {
                  for (String values in messageids.keys) {
                    int index =
                        _messages.indexWhere((element) => element.id == values);
                    setState(() {
                      _messages.removeAt(index);
                    });
                  }
                  updatingmessages(jsonEncode(_messages), widget.documentid);
                  setState(() {
                    toolbar = !toolbar;
                    messageids.clear();
                  });
                  Fluttertoast.showToast(
                    msg: "Deleted sucessfully",
                    textColor: Colors.white,
                    backgroundColor: const Color.fromARGB(211, 0, 0, 0),
                  );
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  child: const Text(
                    "Delete For Me",
                    style: TextStyle(
                        fontSize: 17.0,
                        color: Color.fromARGB(244, 0, 0, 0),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              !messageids.containsValue(false)
                  ? TextButton(
                      onPressed: () async {
                        for (String values in messageids.keys) {
                          int index = _messages
                              .indexWhere((element) => element.id == values);
                          types.Status status = _messages[index].status!;
                          if (status != types.Status.seen) {
                            try {
                              await ref
                                  .child(
                                      "${widget.documentid}/latsmessage/$values/")
                                  .remove();
                              int index = _messages.indexWhere(
                                  (element) => element.id == values);
                              setState(() {
                                _messages.removeAt(index);
                              });
                            } catch (err) {
                              Fluttertoast.showToast(
                                msg: err.toString(),
                                textColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(211, 0, 0, 0),
                              );
                            }
                          } else {
                            // try {
                            //   DataSnapshot ids = await ref
                            //       .child(
                            //           "${widget.documentid}/deletemessage/${widget.documentid}/ids")
                            //       .get();
                            //   if (ids.value != null) {
                            //     List<dynamic> listIDs = ids.value as List;
                            //     await ref
                            //         .child(
                            //             "${widget.documentid}/deletemessage/${widget.documentid}")
                            //         .update({
                            //       "ids": listIDs + [values]
                            //     });
                            //   } else {
                            //     await ref
                            //         .child(
                            //             "${widget.documentid}/deletemessage/${widget.documentid}")
                            //         .update({
                            //       'ids': [values]
                            //     });
                            //   }
                            try {
                              int index = _messages.indexWhere(
                                  (element) => element.id == values);
                              setState(() {
                                _messages.removeAt(index);
                              });
                              await ref
                                  .child("${widget.documentid}/deletemessages")
                                  .update({values: true});
                            } catch (err) {
                              Fluttertoast.showToast(
                                msg: err.toString(),
                                textColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(211, 0, 0, 0),
                              );
                            }
                          }

                          // setState(() {
                          //   _messages.removeAt(index);
                          // });
                        }
                        updatingmessages(
                            jsonEncode(_messages), widget.documentid);
                        setState(() {
                          toolbar = !toolbar;
                          messageids.clear();
                        });
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(textScaleFactor: 1.0),
                        child: const Text(
                          "Delete For Everyone",
                          style: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(244, 0, 0, 0),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()
            ],
          ),
        ),
      ),
    );
  }

  // report function not completed
  Popupbutton(BuildContext c) {
    return PopupMenuButton(
      itemBuilder: (c) {
        return [
          PopupMenuItem<int>(
            value: 1,
            child: chatended
                ? MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                    child: const Text(
                      "Conversation Ended",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  )
                : MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                    child: const Text(
                      "End Conversation",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
          ),
          PopupMenuItem(
            value: 2,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: const Text(
                "Report",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ),
          )
        ];
      },
      onSelected: (value) async {
        if (value == 1) {
          try {
            if (chatended) {
              Fluttertoast.showToast(
                msg: "Conversation ended",
                textColor: Colors.white,
                backgroundColor: const Color.fromARGB(211, 0, 0, 0),
              );
            } else {
              await FirebaseFirestore.instance
                  .collection("chatdata")
                  .doc(widget.documentid)
                  .update({"endchat": true});
              setState(
                () => chatended = true,
              );
              Fluttertoast.showToast(
                msg: "Conversation ended successfully",
                textColor: Colors.white,
                backgroundColor: const Color.fromARGB(211, 0, 0, 0),
              );
            }
          } on Exception catch (err) {
            Fluttertoast.showToast(
              msg: err.toString(),
              textColor: Colors.white,
              backgroundColor: const Color.fromARGB(211, 0, 0, 0),
            );
          }
        }
        if (value == 2) {
          try {
            Fluttertoast.showToast(msg: "Thanks for reporting.");
            // await FirebaseFirestore.instance
            //     .collection("chatdata")
            //     .doc(widget.documentid)
            //     .update({"endchat": true});
            // Fluttertoast.showToast(
            //   msg: "Conversation ended successfully",
            //   textColor: Colors.white,
            //   backgroundColor: const Color.fromARGB(211, 0, 0, 0),
            // );
          } on Exception catch (err) {
            Fluttertoast.showToast(
              msg: err.toString(),
              textColor: Colors.white,
              backgroundColor: const Color.fromARGB(211, 0, 0, 0),
            );
          }

          Fluttertoast.showToast(
            msg: "User has been reported successfully",
            textColor: Colors.white,
            backgroundColor: const Color.fromARGB(211, 0, 0, 0),
          );
        }
      },
    );
  }

  Widget messagestyle(types.TextMessage message,
      {required int messagewidth, required bool showName}) {
    return Text(
      message.text,
      style: const TextStyle(
        fontSize: 14,
      ),
    );
  }

  onsendpressedfunction(types.PartialText message) async {
    int time = DateTime.now().millisecondsSinceEpoch;
    String id = const Uuid().v4();
    final textmessage = types.TextMessage(
        createdAt: time,
        author: _user,
        text: message.text,
        id: id,
        status: types.Status.sending);
    addmessages(textmessage);
    List text_array = [];
    int length_index = (message.text.length ~/ 100);
    for (var i = 0; i < length_index + 1; i++) {
      if (i == length_index) {
        text_array
            .add(encrypter!.encrypt(message.text.substring(i * 100)).base64);
      } else {
        text_array.add(encrypter!
            .encrypt(message.text.substring(i * 100, (i + 1) * 100))
            .base64);
      }
    }
    Map<String, dynamic> data = {
      "createdAt": time,
      "author":
          encrypter!.encrypt(FirebaseAuth.instance.currentUser!.uid).base64,
      "text": text_array,
      "id": id,
      "status": "sent"
    };
    Map<dynamic, dynamic> data1 = {
      'to': notificationtoken,
      'priority': 'high',
      'data': {
        'title': 'Anonymous Chat',
        'body': "A specific individual sent you a message",
        'type': 'confession',
        'confession': widget.confession.toJson()
      }
    };
    if (status != 'online') {
      http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        body: jsonEncode(data1),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'key=AAAAtA6V0JA:APA91bEwrE_GBMBe-aWVap09EcR0H9peWaMIY3nM9ewzsxCxjYL9gbBuGPIIPvs-jStFGTMnFI6cq7Lw_bH3yaRuuwymAVppZO1Y6fGI45QgscvFzEfYXHIrn9on6b68y1F59Jg6KweO'
        },
      );
    }
    ref
        .child("${widget.documentid}/latsmessage/$id")
        .update(data)
        .then((value) {
      int index = _messages.indexWhere((element) => element.id == id);
      types.Message message =
          _messages[index].copyWith(status: types.Status.sent);
      setState(
        () => _messages[index] = message,
      );
      updatingmessages(jsonEncode(_messages), widget.documentid);
    });
    updatingmessages(jsonEncode(_messages), widget.documentid);
  }

  Widget bubble(Widget child,
      {required types.Message message, required bool nextMessageInGroup}) {
    return InkWell(
      onTap: () => messagetap(message),
      onLongPress: () => messagelongpress(message),
      child: ChatBubble(
          backGroundColor: messageids.containsKey(message.id)
              ? Colors.grey
              : message.author == _user
                  ? const Color.fromARGB(255, 3, 163, 237)
                  : Colors.grey[100],
          alignment:
              message.author == _user ? Alignment.topRight : Alignment.topLeft,
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0)
              .copyWith(
                  right: message.author == _user ? 9.0 : 0.0,
                  left: message.author == _user ? 0.0 : 9.0),
          clipper: message.author == _user
              ? (nextMessageInGroup
                  ? ChatBubbleClipper5(type: BubbleType.sendBubble)
                  : ChatBubbleClipper1(type: BubbleType.sendBubble))
              : (nextMessageInGroup
                  ? ChatBubbleClipper5(type: BubbleType.receiverBubble)
                  : ChatBubbleClipper1(type: BubbleType.receiverBubble)),
          child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Models.User currentUser = Provider.of<UserProvider>(context).getUser!;
    return Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 26, 123, 203),
            automaticallyImplyLeading: false,
            titleSpacing: 0.0,
            title: Container(
              height: 57.0,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.lightBlue,
                  Color.fromARGB(255, 26, 123, 203),
                ], begin: Alignment.centerLeft, end: Alignment.centerRight),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (toolbar) {
                        setState(() {
                          toolbar = !toolbar;
                          messageids = {};
                        });
                      } else {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 30.0,
                      color: Color.fromARGB(255, 249, 249, 249),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5.0, bottom: 2.0),
                        child: Text(
                          'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: Text(
                          status,
                          style: const TextStyle(
                              fontSize: 13.0, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                  Flexible(child: Container()),
                ],
              ),
            ),
            actions: !toolbar
                ? [Popupbutton(context)]
                : [
                    const SizedBox(width: 10),
                    IconButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(
                              text: messagescopy(_messages, messageids)
                                  .join(" ")));
                          Fluttertoast.showToast(
                            msg: "Copied successfully",
                            textColor: Colors.white,
                            backgroundColor: const Color.fromARGB(211, 0, 0, 0),
                          );
                        },
                        icon: const Icon(
                          Icons.copy,
                          color: Colors.white,
                        )),
                    IconButton(
                      onPressed: () async {
                        await deletedialog(
                          context,
                        );
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                  ],
          ),
          body: Chat(
            messages: _messages,
            onSendPressed: onsendpressedfunction,
            user: _user,
            bubbleBuilder: bubble,
            inputOptions: InputOptions(
              onTextChanged: keyboardlistner,
              sendButtonVisibilityMode: chatended
                  ? SendButtonVisibilityMode.hidden
                  : SendButtonVisibilityMode.editing,
            ),
            textMessageOptions:
                const TextMessageOptions(isTextSelectable: false),
            theme: DefaultChatTheme(
              sendButtonIcon: const Icon(
                Icons.send,
                color: Color.fromARGB(255, 30, 146, 241),
                size: 27.0,
              ),
              inputTextCursorColor: Colors.lightBlue,
              inputTextColor: const Color.fromARGB(255, 0, 0, 0),
              inputContainerDecoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.lightBlue, width: 2.0),
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              backgroundColor: const Color.fromARGB(255, 248, 248, 248),
              inputMargin: const EdgeInsets.only(bottom: 2, left: 5, right: 5),
              sentEmojiMessageTextStyle: const TextStyle(fontSize: 20),
              inputBorderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
      ),
    );
  }
}

loading(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          Text(
            "messages are syncing",
            style: TextStyle(color: Colors.white, fontSize: 7),
          )
        ],
      ),
    ),
  );
}
