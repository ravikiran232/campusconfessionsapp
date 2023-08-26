import 'dart:convert';

import 'package:another_transformer_page_view/another_transformer_page_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:untitled2/anonymous_namecard_widget.dart';
import 'package:untitled2/comments_page.dart';
import 'package:untitled2/Custom_IconText_button.dart';
import 'package:untitled2/confession_home_page.dart';
import 'package:untitled2/firestore_methods.dart';
import 'package:untitled2/models.dart';
import 'package:untitled2/share_services.dart';
import 'package:untitled2/single_reaction_widget.dart';
import 'package:untitled2/custom_vertical_divider.dart';
import 'package:untitled2/utils.dart';
import 'package:untitled2/vote_animationII.dart';
import 'package:untitled2/vote_clipper.dart';
import 'mail_servicesII.dart';
import 'models.dart' as Models;
import 'package:untitled2/user_provider.dart';
import 'chat_utils/chat_creation.dart';
import 'chat_utils/product_chat_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'transformers.dart';
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:http/http.dart' as http;

class UserConfessionPage extends StatefulWidget {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  int rank;
  Confession confession;
  String avatarURL;
  bool firstTime;
  bool fromBeforePageView;
  UserConfessionPage({
    super.key,
    required this.publicKey,
    required this.privateKey,
    required this.confession,
    required this.avatarURL,
    required this.firstTime,
    this.fromBeforePageView = false,
    this.rank = -1,
  });

  @override
  State<UserConfessionPage> createState() => _UserConfessionPageState();
}

class _UserConfessionPageState extends State<UserConfessionPage> {
  String reaction = 'none';
  bool isUpVoteAnimating = false;
  bool isDownVoteAnimating = false;
  bool enableReactions = false;
  bool justInitialized = true;
  bool isChatContainerExpanded = false;
  bool isNotifyContainerExpanded = false;
  bool showChatButton = false;
  bool showNotifyButton = false;
  bool isNotifyLoading = false;
  bool isChatLoading = false;
  Map<String, String> specificIndividualMailsToIDs = {};
  int pollTotalVotes = 0;
  bool isConfessionDeleteLoading = false;

  final FirestoreMethods _firestoreMethods = FirestoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ShareServices _shareServices = ShareServices();

  final List medal_asset_paths = [
    'assets/images/gold_medal.png',
    'assets/images/silver_medal.png',
    'assets/images/bronze_medal.png'
  ];

  List<double> emojiState = [0, 0, 0, 0, 0, 0, 0];
  double currentHoverposition = 0;
  int currentSelectedEmoji = -1;

  final List<Models.Emoji> emojis = [
    Models.Emoji(path: 'assets/emoticons/9420-thumbs-up.json', scale: 1.2),
    Models.Emoji(
        path: 'assets/emoticons/11057-simple-elegant-like-heart-animation.json',
        scale: 1.0),
    Models.Emoji(path: 'assets/emoticons/2093-laugh.json', scale: 1.0),
    Models.Emoji(
        path: 'assets/emoticons/114067-wink-tongue-out-emoji-animation.json',
        scale: 1.25),
    Models.Emoji(path: 'assets/emoticons/2086-wow.json', scale: 1.0),
    Models.Emoji(path: 'assets/emoticons/34175-sad-face.json', scale: 0.9),
    Models.Emoji(path: 'assets/emoticons/51920-angry.json', scale: 1.25),
  ];

  final List<String> reactions = [
    'like',
    'love',
    'haha',
    'wink',
    'woah',
    'sad',
    'angry'
  ];

  final Map<String, SingleReactionWidget> reactionButtons = {
    'like': SingleReactionWidget(
      label: 'like',
      label_color: Colors.blue,
      emoji_path: 'assets/emoticons/82649-thumbs-up.json',
      lottie: true,
    ),
    'love': SingleReactionWidget(
      label: 'love',
      label_color: Colors.red,
      emoji: '❤️',
    ),
    'haha': SingleReactionWidget(
      label: 'haha',
      label_color: Colors.amber,
      emoji: '😆',
    ),
    'wink': SingleReactionWidget(
      label: 'wink',
      label_color: Colors.amber,
      emoji: '😜',
    ),
    'woah': SingleReactionWidget(
      label: 'woah',
      label_color: Colors.amber,
      emoji: '😯',
    ),
    'sad': SingleReactionWidget(
      label: 'sad',
      label_color: Colors.amber,
      emoji: '😔',
    ),
    'angry': SingleReactionWidget(
      label: 'angry',
      label_color: Colors.orange,
      emoji: '😡',
    ),
  };

  String? confessionSharedKey;
  en.Encrypter? encrypter;

  @override
  void initState() {
    super.initState();
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    final en.Encrypter decrypter =
        en.Encrypter(en.RSA(privateKey: widget.privateKey));
    if (widget.confession.encryptedSharedKeys != null) {
      for (int i = 0; i < widget.confession.encryptedSharedKeys!.length; i++) {
        try {
          confessionSharedKey = decrypter.decrypt(en.Encrypted.fromBase64(
              widget.confession.encryptedSharedKeys![i]));
          encrypter =
              en.Encrypter(en.AES(en.Key.fromBase64(confessionSharedKey!)));
          List<String> encryptedSpecificIndividualUserIDs =
              widget.confession.chatRoomIDs.keys.toList();
          List<String> decryptedSpecificIndividualUserIDs = [];
          for (int i = 0; i < encryptedSpecificIndividualUserIDs.length; i++) {
            decryptedSpecificIndividualUserIDs.add(encrypter!.decrypt(
                en.Encrypted.fromBase64(encryptedSpecificIndividualUserIDs[i]),
                iv: en.IV.fromBase64('campus12')));
          }
          getEmailsFromIDs(decryptedSpecificIndividualUserIDs);
          break;
        } catch (err) {}
      }
    }
  }

  void nextEmoji() {
    currentSelectedEmoji < emojis.length - 1
        ? currentSelectedEmoji++
        : currentSelectedEmoji = emojis.length - 1;
    for (int j = 0; j < emojiState.length; j++) {
      if (currentSelectedEmoji != -1) {
        j == currentSelectedEmoji ? emojiState[j] = 0.5 : emojiState[j] = -0.3;
      } else {
        emojiState[j] = 0;
      }
    }
  }

  void prevEmoji() {
    currentSelectedEmoji > 0
        ? currentSelectedEmoji--
        : currentSelectedEmoji = 0;
    for (int j = 0; j < emojiState.length; j++) {
      if (currentSelectedEmoji != -1) {
        j == currentSelectedEmoji ? emojiState[j] = 0.5 : emojiState[j] = -0.3;
      } else {
        emojiState[j] = 0;
      }
    }
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet ||
        connectivityResult == ConnectivityResult.vpn) {
      return true;
    }
    return false;
  }

  Future<void> _upvoted(
      DocumentSnapshot<Map<String, dynamic>> confession_snapshot,
      {bool disable = false}) async {
    if (disable) {
      String res = await _firestoreMethods.actionOnConfession(
          'disable_upvote',
          widget.confession.confessionId!,
          _auth.currentUser!.uid,
          confession_snapshot);
    } else {
      await _firestoreMethods.actionOnConfession(
          'disable_downvote',
          widget.confession.confessionId!,
          _auth.currentUser!.uid,
          confession_snapshot);
      String res = await _firestoreMethods.actionOnConfession(
          'enable_upvote',
          widget.confession.confessionId!,
          _auth.currentUser!.uid,
          confession_snapshot);
    }
  }

  Future<void> _downvoted(
      DocumentSnapshot<Map<String, dynamic>> confession_snapshot,
      {bool disable = false}) async {
    if (disable) {
      String res = await _firestoreMethods.actionOnConfession(
          'disable_downvote',
          widget.confession.confessionId!,
          _auth.currentUser!.uid,
          confession_snapshot);
    } else {
      await _firestoreMethods.actionOnConfession(
          'disable_upvote',
          widget.confession.confessionId!,
          _auth.currentUser!.uid,
          confession_snapshot);
      String res = await _firestoreMethods.actionOnConfession(
          'enable_downvote',
          widget.confession.confessionId!,
          _auth.currentUser!.uid,
          confession_snapshot);
    }
  }

  Future<String> _reacted(int reaction_idx,
      DocumentSnapshot<Map<String, dynamic>> confession_snapshot,
      {bool disable = false}) async {
    String res = 'Some error occurred.';
    if (reaction_idx == 0) {
      disable
          ? await _firestoreMethods.actionOnConfession(
              'disable_like',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot)
          : await _firestoreMethods.actionOnConfession(
              'enable_like',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot);
      res = 'like';
    } else if (reaction_idx == 1) {
      disable
          ? await _firestoreMethods.actionOnConfession(
              'disable_love',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot)
          : await _firestoreMethods.actionOnConfession(
              'enable_love',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot);
      res = 'love';
    } else if (reaction_idx == 2) {
      disable
          ? await _firestoreMethods.actionOnConfession(
              'disable_haha',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot)
          : await _firestoreMethods.actionOnConfession(
              'enable_haha',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot);
      res = 'haha';
    } else if (reaction_idx == 3) {
      disable
          ? await _firestoreMethods.actionOnConfession(
              'disable_wink',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot)
          : await _firestoreMethods.actionOnConfession(
              'enable_wink',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot);
      res = 'wink';
    } else if (reaction_idx == 4) {
      disable
          ? await _firestoreMethods.actionOnConfession(
              'disable_woah',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot)
          : await _firestoreMethods.actionOnConfession(
              'enable_woah',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot);
      res = 'woah';
    } else if (reaction_idx == 5) {
      disable
          ? await _firestoreMethods.actionOnConfession(
              'disable_sad',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot)
          : await _firestoreMethods.actionOnConfession(
              'enable_sad',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot);
      res = 'sad';
    } else if (reaction_idx == 6) {
      disable
          ? await _firestoreMethods.actionOnConfession(
              'disable_angry',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot)
          : await _firestoreMethods.actionOnConfession(
              'enable_angry',
              widget.confession.confessionId!,
              _auth.currentUser!.uid,
              confession_snapshot);
      res = 'angry';
    }
    return res;
  }

  int _reactionToIdx(String reaction) {
    int res = -1;
    if (reaction == 'like') {
      res = 0;
    } else if (reaction == 'love') {
      res = 1;
    } else if (reaction == 'haha') {
      res = 2;
    } else if (reaction == 'wink') {
      res = 3;
    } else if (reaction == 'woah') {
      res = 4;
    } else if (reaction == 'sad') {
      res = 5;
    } else if (reaction == 'angry') {
      res = 6;
    }
    return res;
  }

  String _searchReactionFromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot, String user_uid) {
    String res = 'Some error occurred.';
    if (snapshot['reactions']['like'].contains(user_uid)) {
      res = 'like';
    } else if (snapshot['reactions']['love'].contains(user_uid)) {
      res = 'love';
    } else if (snapshot['reactions']['haha'].contains(user_uid)) {
      res = 'haha';
    } else if (snapshot['reactions']['wink'].contains(user_uid)) {
      res = 'wink';
    } else if (snapshot['reactions']['woah'].contains(user_uid)) {
      res = 'woah';
    } else if (snapshot['reactions']['sad'].contains(user_uid)) {
      res = 'sad';
    } else if (snapshot['reactions']['angry'].contains(user_uid)) {
      res = 'angry';
    } else {
      res = 'none';
    }
    return res;
  }

  Future<void> getEmailsFromIDs(List<String> userIDs) async {
    Map<String, String> emailsToIDs = {};
    for (String userID in userIDs) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userID).get();
      if (doc.exists) {
        emailsToIDs[doc['email']] = userID;
      }
    }
    if (emailsToIDs != {}) {
      setState(
        () => specificIndividualMailsToIDs = emailsToIDs,
      );
    }
  }

  int getPollTotalVotes(Map<dynamic, dynamic> options) {
    num res = 0;
    for (int i = 1; i <= 4; i++) {
      if (options[i.toString()] != null) {
        res += options[i.toString()]![options[i.toString()]!.keys.toList()[0]]!
            .length;
      }
    }
    return res.toInt();
  }

  int getPollOptionVotes(String optionNumber, Map<dynamic, dynamic> options) {
    num res = -1;
    if (options[optionNumber] != null) {
      res = options[optionNumber]![options[optionNumber]!.keys.toList()[0]]!
          .length;
    }
    return res.toInt();
  }

  List<String> getPollOptionLabels(
      AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> confessionSnap) {
    List<String> res = [];
    for (int i = 1; i <= 4; i++) {
      if (confessionSnap.data!['poll']['options'][i.toString()] != null) {
        res.add(confessionSnap.data!['poll']['options'][i.toString()].keys
            .toList()[0]);
      }
    }
    return res;
  }

  String getCurrentUserPollVote(Map<dynamic, dynamic> options) {
    for (int i = 1; i <= 4; i++) {
      if (options[i.toString()] != null &&
          options[i.toString()][options[i.toString()].keys.toList()[0]]
              .contains(_auth.currentUser!.uid)) {
        return i.toString();
      }
    }
    return 'none';
  }

  @override
  Widget build(BuildContext context) {
    final Models.User currentUser = Provider.of<UserProvider>(context).getUser!;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: WillPopScope(
        onWillPop: () async {
          if (widget.firstTime || widget.fromBeforePageView) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => ConfessionHomePage()));
          } else {
            Navigator.of(context).pop();
          }
          return isConfessionDeleteLoading;
        },
        child: isConfessionDeleteLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : StreamBuilder(
                stream: _firestore
                    .collection('confessions')
                    .doc(widget.confession.confessionId)
                    .snapshots(),
                builder: (context,
                    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                        snapshot) {
                  if (snapshot.connectionState == ConnectionState.none) {
                    return const Center(
                      child: Text('Please check your internet connection'),
                    );
                  } else if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      justInitialized) {
                    justInitialized = false;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    reaction = snapshot.data != null
                        ? _searchReactionFromSnapshot(
                            snapshot.data!, _auth.currentUser!.uid)
                        : 'none';
                    return Scaffold(
                      backgroundColor: Colors.grey,
                      appBar: AppBar(
                        elevation: 0.0,
                        backgroundColor:
                            const Color.fromARGB(255, 27, 130, 213),
                        leading: IconButton(
                          onPressed: () {
                            if (widget.firstTime || widget.fromBeforePageView) {
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ConfessionHomePage()));
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 30.0,
                            color: Color.fromARGB(255, 237, 237, 237),
                          ),
                        ),
                        centerTitle: true,
                        title: Text(
                          'Confession #${widget.confession.confession_no}',
                          style: GoogleFonts.caveat(
                            textStyle: const TextStyle(
                                fontSize: 26.0,
                                fontWeight: FontWeight.w900,
                                color: Color.fromARGB(255, 255, 255, 255),
                                letterSpacing: 0.5),
                          ),
                        ),
                        actions: [
                          IconButton(
                            onPressed: () {
                              setState(
                                () {
                                  enableReactions = false;
                                  showChatButton = false;
                                  isChatContainerExpanded = false;
                                },
                              );
                              showModalBottomSheet(
                                enableDrag: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20.0),
                                    topRight: Radius.circular(20.0),
                                  ),
                                ),
                                context: context,
                                builder: (context) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context)
                                        .copyWith(textScaleFactor: 1.0),
                                    child: SingleChildScrollView(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 10.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color.fromARGB(
                                                        255, 61, 61, 61),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(5.0),
                                                    ),
                                                  ),
                                                  child: SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.2,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.005,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            snapshot.data!['user_uid'] ==
                                                        encrypter
                                                            ?.encrypt(
                                                                _auth
                                                                    .currentUser!
                                                                    .uid,
                                                                iv: en.IV
                                                                    .fromBase64(
                                                                        'campus12'))
                                                            .base64 ||
                                                    widget.confession
                                                        .specificIndividuals
                                                        .contains(encrypter
                                                            ?.encrypt(
                                                                currentUser
                                                                    .email,
                                                                iv: en.IV
                                                                    .fromBase64(
                                                                        'campus12'))
                                                            .base64)
                                                ? SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.01,
                                                  )
                                                : Container(),
                                            snapshot.data!['user_uid'] ==
                                                    encrypter
                                                        ?.encrypt(
                                                            _auth.currentUser!
                                                                .uid,
                                                            iv: en.IV
                                                                .fromBase64(
                                                                    'campus12'))
                                                        .base64
                                                ? Stack(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            'This is your confession',
                                                            style: GoogleFonts
                                                                .secularOne(
                                                              fontSize: 20.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w100,
                                                              color: const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  61,
                                                                  61,
                                                                  61),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            showDialog(
                                                          context: context,
                                                          builder: (_) =>
                                                              SimpleDialog(
                                                            titlePadding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        20.0,
                                                                    vertical:
                                                                        20.0),
                                                            title: const Text(
                                                              "Are you sure? Once deleted, you cannot revert your confession back.",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      17.0),
                                                            ),
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceEvenly,
                                                                children: [
                                                                  InkWell(
                                                                    onTap: () =>
                                                                        Navigator.of(context)
                                                                            .pop(),
                                                                    child:
                                                                        const Padding(
                                                                      padding: EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              10.0,
                                                                          vertical:
                                                                              5.0),
                                                                      child:
                                                                          Text(
                                                                        "Cancel",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                17.0,
                                                                            fontWeight:
                                                                                FontWeight.w500),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      setState(
                                                                        () => isConfessionDeleteLoading =
                                                                            true,
                                                                      );
                                                                      try {
                                                                        await _firestore
                                                                            .collection('confessions')
                                                                            .doc(widget.confession.confessionId)
                                                                            .delete();
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                        Navigator.of(context)
                                                                            .pushReplacement(
                                                                          MaterialPageRoute(
                                                                              builder: (_) => ConfessionHomePage()),
                                                                        );
                                                                      } catch (err) {
                                                                        Fluttertoast
                                                                            .showToast(
                                                                          msg:
                                                                              'Some error occurred. Please try again.',
                                                                          textColor:
                                                                              Colors.white,
                                                                          backgroundColor: const Color.fromARGB(
                                                                              211,
                                                                              0,
                                                                              0,
                                                                              0),
                                                                        );
                                                                      }
                                                                      setState(
                                                                        () => isConfessionDeleteLoading =
                                                                            false,
                                                                      );
                                                                    },
                                                                    child:
                                                                        const Padding(
                                                                      padding: EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              10.0,
                                                                          vertical:
                                                                              5.0),
                                                                      child:
                                                                          Text(
                                                                        "Delete",
                                                                        style: TextStyle(
                                                                            color: Color.fromARGB(
                                                                                255,
                                                                                241,
                                                                                64,
                                                                                51),
                                                                            fontSize:
                                                                                17.0,
                                                                            fontWeight:
                                                                                FontWeight.w500),
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                          size: 20.0,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : widget.confession
                                                        .specificIndividuals
                                                        .contains(encrypter
                                                            ?.encrypt(
                                                                currentUser
                                                                    .email,
                                                                iv: en.IV
                                                                    .fromBase64(
                                                                        'campus12'))
                                                            .base64)
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            'This confession is for you!',
                                                            style: GoogleFonts
                                                                .secularOne(
                                                              fontSize: 18.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w100,
                                                              color: const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  61,
                                                                  61,
                                                                  61),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Container(),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Reactions: ',
                                                      style: GoogleFonts
                                                          .secularOne(
                                                        fontSize: 18.0,
                                                        fontWeight:
                                                            FontWeight.w100,
                                                        color: const Color
                                                                .fromARGB(
                                                            255, 61, 61, 61),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${snapshot.data!['reactions']['like'].length + snapshot.data!['reactions']['love'].length + snapshot.data!['reactions']['haha'].length + snapshot.data!['reactions']['wink'].length + snapshot.data!['reactions']['woah'].length + snapshot.data!['reactions']['sad'].length + snapshot.data!['reactions']['angry'].length}',
                                                      style: GoogleFonts
                                                          .secularOne(
                                                        fontSize: 18.0,
                                                        fontWeight:
                                                            FontWeight.w100,
                                                        color: const Color
                                                                .fromARGB(
                                                            255, 61, 61, 61),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    snapshot
                                                                .data![
                                                                    'reactions']
                                                                    ['like']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              SingleReactionWidget(
                                                                label: '',
                                                                emoji_path:
                                                                    'assets/emoticons/82649-thumbs-up.json',
                                                                lottie: true,
                                                                showLabel:
                                                                    false,
                                                              ),
                                                              Text(
                                                                ': ${snapshot.data!['reactions']['like'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    snapshot
                                                                .data![
                                                                    'reactions']
                                                                    ['love']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '❤️',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${snapshot.data!['reactions']['love'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    snapshot
                                                                .data![
                                                                    'reactions']
                                                                    ['haha']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😆',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${snapshot.data!['reactions']['haha'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    snapshot
                                                                .data![
                                                                    'reactions']
                                                                    ['wink']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😜',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${snapshot.data!['reactions']['wink'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    snapshot
                                                                .data![
                                                                    'reactions']
                                                                    ['woah']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😯',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${snapshot.data!['reactions']['woah'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    snapshot
                                                                .data![
                                                                    'reactions']
                                                                    ['sad']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😔',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${snapshot.data!['reactions']['sad'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    snapshot
                                                                .data![
                                                                    'reactions']
                                                                    ['angry']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😡',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${snapshot.data!['reactions']['angry'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            widget.confession
                                                        .specificIndividuals
                                                        .contains(currentUser
                                                            .email) &&
                                                    widget.confession
                                                        .enableAnonymousChat
                                                ? SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.01,
                                                  )
                                                : Container(),
                                            widget.confession.enablePoll
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Column(
                                                        children: [
                                                          Text(
                                                            'This confession comes with a poll. Click on',
                                                            style: GoogleFonts
                                                                .secularOne(
                                                              fontSize: 15.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w100,
                                                              color: const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  61,
                                                                  61,
                                                                  61),
                                                            ),
                                                          ),
                                                          Text(
                                                            'the avatar to participate.',
                                                            style: GoogleFonts
                                                                .secularOne(
                                                              fontSize: 15.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w100,
                                                              color: const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  61,
                                                                  61,
                                                                  61),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                : Container(),
                                            widget.confession
                                                        .specificIndividuals
                                                        .contains(encrypter
                                                            ?.encrypt(
                                                                currentUser
                                                                    .email,
                                                                iv: en.IV
                                                                    .fromBase64(
                                                                        'campus12'))
                                                            .base64) &&
                                                    widget.confession
                                                        .enableAnonymousChat
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Column(
                                                        children: [
                                                          Text(
                                                            'Confessor wants to chat with you. Click on the',
                                                            style: GoogleFonts
                                                                .secularOne(
                                                              fontSize: 15.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w100,
                                                              color: const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  61,
                                                                  61,
                                                                  61),
                                                            ),
                                                          ),
                                                          Text(
                                                            'chat button for anonymous conversation.',
                                                            style: GoogleFonts
                                                                .secularOne(
                                                              fontSize: 15.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w100,
                                                              color: const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  61,
                                                                  61,
                                                                  61),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                : Container(),
                                            snapshot.data!['user_uid'] ==
                                                        encrypter
                                                            ?.encrypt(
                                                                _auth
                                                                    .currentUser!
                                                                    .uid,
                                                                iv: en.IV
                                                                    .fromBase64(
                                                                        'campus12'))
                                                            .base64 &&
                                                    snapshot
                                                            .data![
                                                                'specificIndividuals']
                                                            .length !=
                                                        0
                                                ? SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.01,
                                                  )
                                                : Container(),
                                            snapshot.data!['user_uid'] ==
                                                        encrypter
                                                            ?.encrypt(
                                                                _auth
                                                                    .currentUser!
                                                                    .uid,
                                                                iv: en.IV
                                                                    .fromBase64(
                                                                        'campus12'))
                                                            .base64 &&
                                                    snapshot
                                                            .data![
                                                                'specificIndividuals']
                                                            .length !=
                                                        0
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Specific Individuals: ${snapshot.data!['specificIndividuals'].length}',
                                                        style: GoogleFonts
                                                            .secularOne(
                                                          fontSize: 18.0,
                                                          fontWeight:
                                                              FontWeight.w100,
                                                          color: const Color
                                                                  .fromARGB(
                                                              255, 61, 61, 61),
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              ...(snapshot
                                                                  .data![
                                                                      'specificIndividuals']
                                                                  .map(
                                                                (item) => Text(
                                                                  confessionSharedKey !=
                                                                          null
                                                                      ? encrypter!.decrypt(
                                                                          en.Encrypted.fromBase64(
                                                                              item),
                                                                          iv: en
                                                                              .IV
                                                                              .fromBase64('campus12'))
                                                                      : '',
                                                                  style: GoogleFonts
                                                                      .secularOne(
                                                                    fontSize:
                                                                        17.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w100,
                                                                    color: const Color
                                                                            .fromARGB(
                                                                        255,
                                                                        61,
                                                                        61,
                                                                        61),
                                                                  ),
                                                                ),
                                                              )),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                : Container(),
                                            snapshot.data!['user_uid'] ==
                                                        encrypter
                                                            ?.encrypt(
                                                                _auth
                                                                    .currentUser!
                                                                    .uid,
                                                                iv: en.IV
                                                                    .fromBase64(
                                                                        'campus12'))
                                                            .base64 &&
                                                    snapshot
                                                            .data![
                                                                'specificIndividuals']
                                                            .length !=
                                                        0
                                                ? SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.01,
                                                  )
                                                : Container(),
                                            snapshot.data!['user_uid'] ==
                                                        encrypter
                                                            ?.encrypt(
                                                                _auth
                                                                    .currentUser!
                                                                    .uid,
                                                                iv: en.IV
                                                                    .fromBase64(
                                                                        'campus12'))
                                                            .base64 &&
                                                    snapshot
                                                            .data![
                                                                'specificIndividuals']
                                                            .length !=
                                                        0
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Seen by: ${snapshot.data!['seenBySIs'].length}',
                                                            style: GoogleFonts
                                                                .secularOne(
                                                              fontSize: 18.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w100,
                                                              color: const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  61,
                                                                  61,
                                                                  61),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      ...(snapshot
                                                          .data!['seenBySIs']
                                                          .map(
                                                        (item) {
                                                          return Text(
                                                            encrypter != null
                                                                ? encrypter!.decrypt(
                                                                    en.Encrypted
                                                                        .fromBase64(
                                                                            item),
                                                                    iv: en.IV
                                                                        .fromBase64(
                                                                            'campus12'))
                                                                : '',
                                                            style: GoogleFonts
                                                                .secularOne(
                                                              fontSize: 17.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w100,
                                                              color: const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  61,
                                                                  61,
                                                                  61),
                                                            ),
                                                          );
                                                        },
                                                      ))
                                                    ],
                                                  )
                                                : Container()
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.info_outline,
                              size: 30.0,
                              color: Color.fromARGB(255, 237, 237, 237),
                            ),
                          )
                        ],
                      ),
                      body: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 27, 130, 213),
                                  Color.fromARGB(255, 240, 240, 240),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height < 630.0
                                          ? MediaQuery.of(context).size.height *
                                              0.73
                                          : MediaQuery.of(context).size.height *
                                              0.761,
                                  //color: Colors.amberAccent,
                                  margin: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height *
                                          0.012),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.7,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(3.0),
                                          ),
                                          border: Border.all(
                                              width: 2.5,
                                              color: Colors.black54),
                                          image: const DecorationImage(
                                            fit: BoxFit.cover,
                                            image: AssetImage(
                                                'assets/images/paper_background.jpg'),
                                          ),
                                          color: const Color.fromARGB(
                                              255, 237, 237, 237),
                                        ),
                                        margin: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04,
                                        ).copyWith(
                                            top: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.1,
                                            bottom: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.02),
                                        padding: const EdgeInsets.symmetric(
                                                horizontal: 15.0)
                                            .copyWith(bottom: 10.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.08,
                                            ),
                                            RawScrollbar(
                                              thickness: 5.0,
                                              thumbColor: const Color.fromARGB(
                                                  71, 0, 0, 0),
                                              child: SizedBox(
                                                height: MediaQuery.of(context)
                                                            .size
                                                            .height <
                                                        630.0
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.50
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.535,
                                                child: SingleChildScrollView(
                                                  child: Text(
                                                    widget
                                                        .confession.confession!,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 17.0),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              InkWell(
                                                onTap: () async {
                                                  if (await checkConnectivity()) {
                                                    if (widget.confession
                                                        .enablePoll) {
                                                      showGeneralDialog(
                                                        barrierDismissible:
                                                            true,
                                                        barrierLabel: 'Blah',
                                                        barrierColor:
                                                            const Color
                                                                    .fromARGB(0,
                                                                255, 255, 255),
                                                        context: context,
                                                        transitionDuration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200),
                                                        pageBuilder: (context,
                                                                animation,
                                                                secondaryAnimation) =>
                                                            Container(),
                                                        transitionBuilder:
                                                            (context, anim1,
                                                                anim2, _) {
                                                          try {
                                                            return MediaQuery(
                                                              data: MediaQuery.of(
                                                                      context)
                                                                  .copyWith(
                                                                      textScaleFactor:
                                                                          1.0),
                                                              child:
                                                                  ScaleTransition(
                                                                alignment:
                                                                    Alignment
                                                                        .topCenter,
                                                                scale: Tween<
                                                                            double>(
                                                                        begin:
                                                                            0.5,
                                                                        end:
                                                                            1.0)
                                                                    .animate(
                                                                        anim1),
                                                                child:
                                                                    FadeTransition(
                                                                  opacity: Tween<
                                                                              double>(
                                                                          begin:
                                                                              0.0,
                                                                          end:
                                                                              1.0)
                                                                      .animate(
                                                                          anim1),
                                                                  child:
                                                                      SimpleDialog(
                                                                    contentPadding:
                                                                        const EdgeInsets
                                                                            .symmetric(
                                                                      horizontal:
                                                                          0.0,
                                                                    ).copyWith(
                                                                            top:
                                                                                10.0),
                                                                    elevation:
                                                                        10.0,
                                                                    backgroundColor:
                                                                        const Color.fromARGB(
                                                                            248,
                                                                            255,
                                                                            255,
                                                                            255),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              25.0),
                                                                    ),
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.symmetric(horizontal: 10.0).copyWith(bottom: 15.0),
                                                                        child:
                                                                            Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Container(
                                                                              width: double.infinity,
                                                                              alignment: Alignment.center,
                                                                              margin: EdgeInsets.only(bottom: widget.confession.poll!['question'].length > 120 ? 10.0 : 20.0),
                                                                              child: const Text(
                                                                                'Public Poll',
                                                                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0, color: Colors.black),
                                                                              ),
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(bottom: 5.0),
                                                                              child: Text(
                                                                                widget.confession.poll!['question'],
                                                                                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                                                                              ),
                                                                            ),
                                                                            StreamBuilder(
                                                                              stream: _firestore.collection('confessions').doc(widget.confession.confessionId).snapshots(),
                                                                              builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> currConfessionSnap) {
                                                                                if (currConfessionSnap.connectionState == ConnectionState.none) {
                                                                                  return const Center(child: Text('Please connect to internet to see options'));
                                                                                } else if (currConfessionSnap.connectionState == ConnectionState.waiting) {
                                                                                  return Center(
                                                                                    child: Container(),
                                                                                  );
                                                                                } else {
                                                                                  if (currConfessionSnap.data == null) {
                                                                                    return const Center(
                                                                                      child: Text('Unable to load options'),
                                                                                    );
                                                                                  } else {
                                                                                    int totalVotes = getPollTotalVotes(currConfessionSnap.data!['poll']['options']);
                                                                                    String currUserVote = getCurrentUserPollVote(currConfessionSnap.data!['poll']['options']);
                                                                                    List<String> optionLabels = getPollOptionLabels(currConfessionSnap);
                                                                                    return ListView.builder(
                                                                                      padding: const EdgeInsets.symmetric(vertical: 0.0),
                                                                                      shrinkWrap: true,
                                                                                      itemCount: optionLabels.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        String currOption = (index + 1).toString();
                                                                                        int optionVotes = getPollOptionVotes(currOption, currConfessionSnap.data!['poll']['options']);
                                                                                        if (widget.confession.poll!['options'][currOption] != null && index < optionLabels.length - 1) {
                                                                                          return InkWell(
                                                                                            onTap: () async {
                                                                                              String res = await _firestoreMethods.voteOnPoll(widget.confession.confessionId!, currOption.toString(), optionLabels);
                                                                                              if (res != 'Voted successfully') {
                                                                                                Fluttertoast.showToast(
                                                                                                  msg: 'Some error occurred. Please try again.',
                                                                                                  textColor: Colors.white,
                                                                                                  backgroundColor: const Color.fromARGB(211, 0, 0, 0),
                                                                                                );
                                                                                              }
                                                                                            },
                                                                                            child: Container(
                                                                                              alignment: Alignment.centerLeft,
                                                                                              width: double.infinity,
                                                                                              height: widget.confession.poll!['options'][currOption].keys.toList()[0].length > 24 ? 66.0 : 33.0,
                                                                                              margin: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                                              decoration: BoxDecoration(
                                                                                                border: Border.all(
                                                                                                    color: currUserVote == currOption
                                                                                                        ? const Color.fromARGB(255, 16, 127, 217)
                                                                                                        : currUserVote == 'none'
                                                                                                            ? Colors.black
                                                                                                            : const Color.fromARGB(255, 158, 158, 158),
                                                                                                    width: 1.0),
                                                                                                borderRadius: BorderRadius.circular(5.0),
                                                                                              ),
                                                                                              child: LayoutBuilder(
                                                                                                builder: (context, constraints) {
                                                                                                  return Stack(
                                                                                                    alignment: Alignment.centerLeft,
                                                                                                    children: [
                                                                                                      Padding(
                                                                                                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                                                                                        child: Text(
                                                                                                          widget.confession.poll!['options'][currOption].keys.toList()[0],
                                                                                                          style: TextStyle(
                                                                                                            fontSize: widget.confession.poll!['options'][currOption].keys.toList()[0].length > 24 ? 15.0 : 18.0,
                                                                                                            fontWeight: FontWeight.w500,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                      currUserVote != 'none'
                                                                                                          ? Align(
                                                                                                              alignment: Alignment.topRight,
                                                                                                              child: Text(
                                                                                                                totalVotes != 0 ? '${((optionVotes / totalVotes) * 100).round()}%' : '0%',
                                                                                                                style: TextStyle(
                                                                                                                  fontSize: 12.0,
                                                                                                                  fontWeight: FontWeight.w500,
                                                                                                                ),
                                                                                                              ),
                                                                                                            )
                                                                                                          : Container(),
                                                                                                      AnimatedContainer(
                                                                                                        duration: const Duration(milliseconds: 200),
                                                                                                        width: totalVotes != 0 ? constraints.maxWidth * (optionVotes / totalVotes) : 0.0,
                                                                                                        color: currUserVote == currOption
                                                                                                            ? const Color.fromARGB(97, 16, 127, 217)
                                                                                                            : currUserVote == 'none'
                                                                                                                ? null
                                                                                                                : const Color.fromARGB(117, 158, 158, 158),
                                                                                                      ),
                                                                                                    ],
                                                                                                  );
                                                                                                },
                                                                                              ),
                                                                                            ),
                                                                                          );
                                                                                        } else if (widget.confession.poll!['options'][currOption] != null && index == optionLabels.length - 1) {
                                                                                          return Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              InkWell(
                                                                                                onTap: () async {
                                                                                                  String res = await _firestoreMethods.voteOnPoll(widget.confession.confessionId!, currOption.toString(), optionLabels);
                                                                                                  if (res != 'Voted successfully') {
                                                                                                    Fluttertoast.showToast(
                                                                                                      msg: 'Some error occurred. Please try again.',
                                                                                                      textColor: Colors.white,
                                                                                                      backgroundColor: const Color.fromARGB(211, 0, 0, 0),
                                                                                                    );
                                                                                                  }
                                                                                                },
                                                                                                child: Container(
                                                                                                  alignment: Alignment.centerLeft,
                                                                                                  width: double.infinity,
                                                                                                  height: widget.confession.poll!['options'][currOption].keys.toList()[0].length > 24 ? 66.0 : 33.0,
                                                                                                  margin: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                    border: Border.all(
                                                                                                        color: currUserVote == currOption
                                                                                                            ? const Color.fromARGB(255, 16, 127, 217)
                                                                                                            : currUserVote == 'none'
                                                                                                                ? Colors.black
                                                                                                                : const Color.fromARGB(255, 158, 158, 158),
                                                                                                        width: 1.0),
                                                                                                    borderRadius: BorderRadius.circular(5.0),
                                                                                                  ),
                                                                                                  child: LayoutBuilder(
                                                                                                    builder: (context, constraints) {
                                                                                                      return Stack(
                                                                                                        alignment: Alignment.centerLeft,
                                                                                                        children: [
                                                                                                          Padding(
                                                                                                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                                                                                            child: Text(
                                                                                                              widget.confession.poll!['options'][currOption].keys.toList()[0],
                                                                                                              style: TextStyle(
                                                                                                                fontSize: widget.confession.poll!['options'][currOption].keys.toList()[0].length > 24 ? 15.0 : 18.0,
                                                                                                                fontWeight: FontWeight.w500,
                                                                                                              ),
                                                                                                            ),
                                                                                                          ),
                                                                                                          currUserVote != 'none'
                                                                                                              ? Align(
                                                                                                                  alignment: Alignment.topRight,
                                                                                                                  child: Text(
                                                                                                                    totalVotes != 0 ? '${((optionVotes / totalVotes) * 100).round()}%' : '0%',
                                                                                                                    style: TextStyle(
                                                                                                                      fontSize: 12.0,
                                                                                                                      fontWeight: FontWeight.w500,
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                )
                                                                                                              : Container(),
                                                                                                          AnimatedContainer(
                                                                                                            duration: const Duration(milliseconds: 200),
                                                                                                            width: totalVotes != 0 ? constraints.maxWidth * (optionVotes / totalVotes) : 0.0,
                                                                                                            color: currUserVote == currOption
                                                                                                                ? const Color.fromARGB(97, 16, 127, 217)
                                                                                                                : currUserVote == 'none'
                                                                                                                    ? null
                                                                                                                    : const Color.fromARGB(117, 158, 158, 158),
                                                                                                          ),
                                                                                                        ],
                                                                                                      );
                                                                                                    },
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              currUserVote != 'none'
                                                                                                  ? Container(
                                                                                                      alignment: Alignment.centerRight,
                                                                                                      width: double.infinity,
                                                                                                      padding: const EdgeInsets.symmetric(horizontal: 10.0).copyWith(top: 5.0),
                                                                                                      child: Text(
                                                                                                        'Votes: $totalVotes',
                                                                                                        style: TextStyle(
                                                                                                          fontSize: 12.0,
                                                                                                          fontWeight: FontWeight.w500,
                                                                                                        ),
                                                                                                      ),
                                                                                                    )
                                                                                                  : Container()
                                                                                            ],
                                                                                          );
                                                                                        } else {
                                                                                          return Container();
                                                                                        }
                                                                                      },
                                                                                    );
                                                                                  }
                                                                                }
                                                                              },
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          } catch (err) {
                                                            return ScaleTransition(
                                                              scale: Tween<
                                                                          double>(
                                                                      begin:
                                                                          0.5,
                                                                      end: 1.0)
                                                                  .animate(
                                                                      anim1),
                                                              child:
                                                                  FadeTransition(
                                                                opacity: Tween<
                                                                    double>(
                                                                  begin: 0.0,
                                                                  end: 1.0,
                                                                ).animate(
                                                                    anim1),
                                                                child:
                                                                    SimpleDialog(
                                                                  contentPadding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          0.0,
                                                                      vertical:
                                                                          10.0),
                                                                  elevation:
                                                                      10.0,
                                                                  backgroundColor:
                                                                      const Color
                                                                              .fromARGB(
                                                                          248,
                                                                          255,
                                                                          255,
                                                                          255),
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            25.0),
                                                                  ),
                                                                  children: [
                                                                    Text(
                                                                        'Some error occurred. Please come back later.')
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      );
                                                    } else {
                                                      return;
                                                    }
                                                  } else {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          'Please check your internet connection',
                                                      textColor: Colors.white,
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                              211, 0, 0, 0),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: widget.confession
                                                            .enablePoll
                                                        ? null
                                                        : Colors.white,
                                                    gradient: widget.confession
                                                            .enablePoll
                                                        ? const LinearGradient(
                                                            colors: [
                                                              Color.fromARGB(
                                                                  255,
                                                                  146,
                                                                  26,
                                                                  167),
                                                              Color.fromARGB(
                                                                  255,
                                                                  206,
                                                                  84,
                                                                  227),
                                                            ],
                                                          )
                                                        : null,
                                                  ),
                                                  child: CircleAvatar(
                                                    radius:
                                                        MediaQuery.of(context)
                                                                    .size
                                                                    .height <
                                                                630.0
                                                            ? 42.0
                                                            : 51.0,
                                                    //backgroundColor: Colors.white,
                                                    backgroundImage:
                                                        const AssetImage(
                                                            'assets/images/default_avatar.jpg'),
                                                    child: Hero(
                                                      tag: widget.confession
                                                          .confessionId!,
                                                      child: CircleAvatar(
                                                        radius: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height <
                                                                630.0
                                                            ? 42.0
                                                            : 51.0,
                                                        backgroundColor:
                                                            const Color
                                                                    .fromARGB(0,
                                                                255, 255, 255),
                                                        backgroundImage: widget
                                                                    .avatarURL ==
                                                                'default'
                                                            ? const AssetImage(
                                                                    'assets/images/default_avatar.jpg')
                                                                as ImageProvider
                                                            : widget.confession
                                                                        .user_uid ==
                                                                    encrypter
                                                                        ?.encrypt(
                                                                            _auth
                                                                                .currentUser!.uid,
                                                                            iv: en.IV.fromBase64(
                                                                                'campus12'))
                                                                        .base64
                                                                ? NetworkImage(_auth
                                                                    .currentUser!
                                                                    .photoURL!)
                                                                : NetworkImage(
                                                                    widget
                                                                        .avatarURL),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 0.0,
                                                child: widget
                                                        .confession.adminPost
                                                    ? AnonymousNameCard(
                                                        isPollEnabled: widget
                                                            .confession
                                                            .enablePoll,
                                                        fromAdmin: true,
                                                      )
                                                    : confessionSharedKey ==
                                                            null
                                                        ? AnonymousNameCard(
                                                            isPollEnabled:
                                                                widget
                                                                    .confession
                                                                    .enablePoll,
                                                          )
                                                        : (widget.confession
                                                                .specificIndividuals
                                                                .contains(encrypter!
                                                                    .encrypt(currentUser.email,
                                                                        iv: en
                                                                            .IV
                                                                            .fromBase64(
                                                                                'campus12'))
                                                                    .base64))
                                                            ? AnonymousNameCard(
                                                                forCurrentUser:
                                                                    true,
                                                                isPollEnabled: widget
                                                                    .confession
                                                                    .enablePoll)
                                                            : (widget.confession
                                                                        .user_uid ==
                                                                    encrypter!
                                                                        .encrypt(
                                                                            _auth.currentUser!.uid,
                                                                            iv: en.IV.fromBase64('campus12'))
                                                                        .base64)
                                                                ? AnonymousNameCard(isCurrentUser: true, isPollEnabled: widget.confession.enablePoll)
                                                                : AnonymousNameCard(
                                                                    isPollEnabled: widget
                                                                        .confession
                                                                        .enablePoll,
                                                                  ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10.0,
                                                vertical: 5.0),
                                            child: Text(
                                              DateFormat.yMMMMd().format(widget
                                                  .confession.datePublished!
                                                  .toDate()),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Container(),
                                ),
                                Container(
                                  width: double.infinity,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 15.0, right: 12.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () async {
                                                setState(
                                                  () =>
                                                      isUpVoteAnimating = false,
                                                );
                                                if (await checkConnectivity()) {
                                                  if (!snapshot.data!['upvotes']
                                                      .contains(_auth
                                                          .currentUser!.uid)) {
                                                    setState(() {
                                                      isUpVoteAnimating = true;
                                                      isDownVoteAnimating =
                                                          false;
                                                    });
                                                    await _upvoted(
                                                        snapshot.data!);
                                                  } else {
                                                    setState(() {
                                                      isUpVoteAnimating = false;
                                                      isDownVoteAnimating =
                                                          false;
                                                    });
                                                    await _upvoted(
                                                        snapshot.data!,
                                                        disable: true);
                                                  }
                                                } else {
                                                  setState(() {
                                                    isUpVoteAnimating = true;
                                                    isDownVoteAnimating = false;
                                                  });
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        'Please check your internet connection',
                                                    textColor: Colors.white,
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                            211, 0, 0, 0),
                                                  );
                                                }
                                              },
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    snapshot.data != null
                                                        ? snapshot
                                                            .data!['upvotes']
                                                            .length
                                                            .toString()
                                                        : '0',
                                                    style:
                                                        GoogleFonts.secularOne(
                                                      textStyle: TextStyle(
                                                        fontSize: 20.0,
                                                        color: snapshot.data !=
                                                                    null &&
                                                                snapshot.data![
                                                                        'upvotes']
                                                                    .contains(_auth
                                                                        .currentUser!
                                                                        .uid)
                                                            ? Colors.green
                                                            : const Color
                                                                    .fromARGB(
                                                                255,
                                                                61,
                                                                61,
                                                                61),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 5.0,
                                                  ),
                                                  isUpVoteAnimating
                                                      ? VoteAnimationII(
                                                          color: Colors.green,
                                                          icon_height: 25.0,
                                                          icon_width: 22.0,
                                                        )
                                                      : VoteClipper(
                                                          color: Colors.green,
                                                          icon_height: 25.0,
                                                          icon_width: 22.0,
                                                        ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 13.0,
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                setState(
                                                  () => isDownVoteAnimating =
                                                      false,
                                                );
                                                if (await checkConnectivity()) {
                                                  if (!snapshot
                                                      .data!['downvotes']
                                                      .contains(_auth
                                                          .currentUser!.uid)) {
                                                    setState(() {
                                                      isDownVoteAnimating =
                                                          true;
                                                      isUpVoteAnimating = false;
                                                    });
                                                    await _downvoted(
                                                        snapshot.data!);
                                                  } else {
                                                    setState(() {
                                                      isDownVoteAnimating =
                                                          false;
                                                      isUpVoteAnimating = false;
                                                    });
                                                    await _downvoted(
                                                        snapshot.data!,
                                                        disable: true);
                                                  }
                                                } else {
                                                  setState(() {
                                                    isDownVoteAnimating = true;
                                                    isUpVoteAnimating = false;
                                                  });
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        'Please check your internet connection',
                                                    textColor: Colors.white,
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                            211, 0, 0, 0),
                                                  );
                                                }
                                              },
                                              child: Row(
                                                children: [
                                                  Text(
                                                    snapshot.data != null
                                                        ? snapshot
                                                            .data!['downvotes']
                                                            .length
                                                            .toString()
                                                        : '0',
                                                    style:
                                                        GoogleFonts.secularOne(
                                                      textStyle: TextStyle(
                                                        fontSize: 20.0,
                                                        color: snapshot.data !=
                                                                    null &&
                                                                snapshot.data![
                                                                        'downvotes']
                                                                    .contains(_auth
                                                                        .currentUser!
                                                                        .uid)
                                                            ? Colors.red
                                                            : const Color
                                                                    .fromARGB(
                                                                255,
                                                                61,
                                                                61,
                                                                61),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 5.0,
                                                  ),
                                                  isDownVoteAnimating
                                                      ? VoteAnimationII(
                                                          color: Colors.red,
                                                          icon_height: 25.0,
                                                          icon_width: 22.0,
                                                        )
                                                      : Transform.translate(
                                                          offset: const Offset(
                                                              0.0, -1.0),
                                                          child:
                                                              Transform.rotate(
                                                            angle:
                                                                1.5707963267948966 *
                                                                    2,
                                                            child: VoteClipper(
                                                              color: Colors.red,
                                                              icon_width: 22.0,
                                                              icon_height: 25.0,
                                                            ),
                                                          ),
                                                        ),
                                                ],
                                              ),
                                            ),
                                            Flexible(child: Container()),
                                            Text(
                                              snapshot.data != null
                                                  ? (snapshot
                                                              .data![
                                                                  'reactions']
                                                                  ['like']
                                                              .length +
                                                          snapshot
                                                              .data![
                                                                  'reactions']
                                                                  ['love']
                                                              .length +
                                                          snapshot
                                                              .data![
                                                                  'reactions']
                                                                  ['haha']
                                                              .length +
                                                          snapshot
                                                              .data![
                                                                  'reactions']
                                                                  ['wink']
                                                              .length +
                                                          snapshot
                                                              .data![
                                                                  'reactions']
                                                                  ['woah']
                                                              .length +
                                                          snapshot
                                                              .data![
                                                                  'reactions']
                                                                  ['sad']
                                                              .length +
                                                          snapshot
                                                              .data![
                                                                  'reactions']
                                                                  ['angry']
                                                              .length)
                                                      .toString()
                                                  : '0',
                                              style: GoogleFonts.secularOne(
                                                fontSize: 20.0,
                                                fontWeight: FontWeight.w100,
                                                color: const Color.fromARGB(
                                                    255, 61, 61, 61),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 2.0,
                                            ),
                                            Text(
                                              'Reactions',
                                              style: GoogleFonts.secularOne(
                                                fontSize: 13.0,
                                                fontWeight: FontWeight.w100,
                                                color: const Color.fromARGB(
                                                    255, 61, 61, 61),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10.0,
                                            ),
                                            Text(
                                              snapshot.data != null
                                                  ? snapshot
                                                      .data!['views'].length
                                                      .toString()
                                                  : '0',
                                              style: GoogleFonts.secularOne(
                                                textStyle: const TextStyle(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.w100,
                                                  color: Color.fromARGB(
                                                      255, 61, 61, 61),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 2.0,
                                            ),
                                            Text(
                                              'views',
                                              style: GoogleFonts.secularOne(
                                                textStyle: const TextStyle(
                                                  fontSize: 13.0,
                                                  fontWeight: FontWeight.w100,
                                                  color: Color.fromARGB(
                                                      255, 61, 61, 61),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        child: Divider(
                                          height: 0.0,
                                          thickness: 1.0,
                                          color:
                                              Color.fromARGB(255, 61, 61, 61),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          reaction == 'none'
                                              ? CustomIconTextButton(
                                                  onPressed: () async {
                                                    setState(() =>
                                                        enableReactions =
                                                            !enableReactions);
                                                  },
                                                  icon: Icons.favorite_border,
                                                  text: 'React')
                                              : TextButton(
                                                  onPressed: () async {
                                                    if (await checkConnectivity()) {
                                                      int reaction_idx =
                                                          _reactionToIdx(
                                                              reaction);
                                                      setState(
                                                        () => reaction = 'none',
                                                      );
                                                      await _reacted(
                                                          reaction_idx,
                                                          snapshot.data!,
                                                          disable: true);
                                                    } else {
                                                      Fluttertoast.showToast(
                                                        msg:
                                                            'Please check your internet connection',
                                                        textColor: Colors.white,
                                                        backgroundColor:
                                                            const Color
                                                                    .fromARGB(
                                                                211, 0, 0, 0),
                                                      );
                                                    }
                                                  },
                                                  style: ButtonStyle(
                                                    overlayColor:
                                                        MaterialStateProperty
                                                            .all(
                                                      const Color.fromARGB(
                                                          255, 220, 220, 220),
                                                    ),
                                                  ),
                                                  child: reactionButtons[
                                                      reaction]!),
                                          CustomVerticalDivider(
                                            color: const Color.fromARGB(
                                                255, 61, 61, 61),
                                            height: 40.0,
                                          ),
                                          CustomIconTextButton(
                                              onPressed: () {
                                                setState(
                                                  () => enableReactions = false,
                                                );
                                                Navigator.push(
                                                  context,
                                                  PageTransition(
                                                      duration: const Duration(
                                                          milliseconds: 200),
                                                      opaque: true,
                                                      child: CommentsPage(
                                                        encrypter: encrypter,
                                                        privateKey:
                                                            widget.privateKey!,
                                                        publicKey:
                                                            widget.publicKey!,
                                                        confessionId: widget
                                                            .confession
                                                            .confessionId!,
                                                        confessionOwner: widget
                                                            .confession
                                                            .user_uid,
                                                      ),
                                                      type: PageTransitionType
                                                          .bottomToTop),
                                                );
                                                encrypter != null &&
                                                        encrypter!
                                                                .encrypt(
                                                                    _auth
                                                                        .currentUser!
                                                                        .uid,
                                                                    iv: en.IV
                                                                        .fromBase64(
                                                                            'campus12'))
                                                                .base64 ==
                                                            widget.confession
                                                                .user_uid
                                                    ? Future.delayed(
                                                        const Duration(
                                                            seconds: 1),
                                                        () => Fluttertoast
                                                            .showToast(
                                                          toastLength:
                                                              Toast.LENGTH_LONG,
                                                          msg:
                                                              'Remember - Your comfort comes first in your confession. You are empowered with deleting any distressing or inappropriate comments.',
                                                          textColor:
                                                              Colors.white,
                                                          backgroundColor:
                                                              const Color
                                                                      .fromARGB(
                                                                  211, 0, 0, 0),
                                                        ),
                                                      )
                                                    : Future.delayed(
                                                        const Duration(
                                                            seconds: 1),
                                                        () => Fluttertoast
                                                            .showToast(
                                                          toastLength:
                                                              Toast.LENGTH_LONG,
                                                          msg:
                                                              "Remember - Words matter. Comment with care, fostering a respectful space for all.",
                                                          textColor:
                                                              Colors.white,
                                                          backgroundColor:
                                                              const Color
                                                                      .fromARGB(
                                                                  211, 0, 0, 0),
                                                        ),
                                                      );
                                                Future.delayed(
                                                  const Duration(seconds: 4),
                                                  () => Fluttertoast.showToast(
                                                    msg:
                                                        'You can act on a comment by long pressing on it.',
                                                    textColor: Colors.white,
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                            211, 0, 0, 0),
                                                  ),
                                                );
                                              },
                                              icon: Icons.comment_outlined,
                                              text: 'Comment'),
                                          CustomVerticalDivider(
                                            color: const Color.fromARGB(
                                                255, 61, 61, 61),
                                            height: 40.0,
                                          ),
                                          CustomIconTextButton(
                                              onPressed: () async {
                                                setState(() {
                                                  isChatContainerExpanded =
                                                      false;
                                                  isChatLoading = false;
                                                  showChatButton = false;
                                                  enableReactions = false;
                                                });
                                                String link =
                                                    await _shareServices
                                                        .createDynamicLink(
                                                            'confessions',
                                                            widget.confession
                                                                .confessionId!);
                                                Share.share(
                                                    """Hey! Stumbled upon a really gripping confession on [Your App's Name]. Seriously worth checking out. Tap the link and dive into the story! 
      
      $link""");
                                              },
                                              icon: Icons.share,
                                              text: 'Share'),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: enableReactions
                                ? MediaQuery.of(context).size.width
                                : 0.0,
                            child: enableReactions
                                ? FittedBox(
                                    fit: BoxFit.contain,
                                    child: Container(
                                      //width: MediaQuery.of(context).size.width,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20.0),
                                        ),
                                        color:
                                            Color.fromARGB(227, 245, 245, 245),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                        vertical: 60.0,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 3.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          for (int i = 0;
                                              i < emojis.length;
                                              i++)
                                            GestureDetector(
                                              onTap: () async {
                                                if (await checkConnectivity()) {
                                                  String res = await _reacted(
                                                      i, snapshot.data!);
                                                  setState(
                                                    () {
                                                      emojiState = [
                                                        0,
                                                        0,
                                                        0,
                                                        0,
                                                        0,
                                                        0,
                                                        0
                                                      ];
                                                      enableReactions = false;
                                                      reaction = res;
                                                    },
                                                  );
                                                } else {
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        'Please check your internet connection',
                                                    textColor: Colors.white,
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                            211, 0, 0, 0),
                                                  );
                                                  setState(
                                                    () {
                                                      enableReactions = false;
                                                      emojiState = [
                                                        0,
                                                        0,
                                                        0,
                                                        0,
                                                        0,
                                                        0,
                                                        0
                                                      ];
                                                    },
                                                  );
                                                }
                                              },
                                              onLongPressDown: (details) {
                                                setState(() {
                                                  for (int j = 0;
                                                      j < emojiState.length;
                                                      j++) {
                                                    j == i
                                                        ? emojiState[j] = 0.5
                                                        : emojiState[j] = -0.3;
                                                  }
                                                  currentSelectedEmoji = i;
                                                });
                                                currentHoverposition =
                                                    details.localPosition.dx;
                                              },
                                              onLongPressMoveUpdate: (details) {
                                                double dragDifference =
                                                    details.localPosition.dx -
                                                        currentHoverposition;
                                                if (dragDifference.abs() >
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.11) {
                                                  if (dragDifference > 0) {
                                                    setState(() {
                                                      nextEmoji();
                                                    });
                                                  } else {
                                                    setState(() {
                                                      prevEmoji();
                                                    });
                                                  }
                                                  currentHoverposition =
                                                      details.localPosition.dx;
                                                }
                                              },
                                              onLongPressUp: () async {
                                                if (await checkConnectivity()) {
                                                  String res = await _reacted(
                                                      currentSelectedEmoji,
                                                      snapshot.data!);
                                                  setState(
                                                    () => reaction = res,
                                                  );
                                                } else {
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        'Please check your internet connection',
                                                    textColor: Colors.white,
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                            211, 0, 0, 0),
                                                  );
                                                }
                                                setState(
                                                  () {
                                                    emojiState = [
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0
                                                    ];
                                                    enableReactions = false;
                                                  },
                                                );
                                              },
                                              child: AnimatedScale(
                                                scale: emojiState[i] == 0
                                                    ? 1.0
                                                    : 1.0 +
                                                        emojiState[i], //befuck
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                child: Transform.scale(
                                                  scale: emojis[i].scale,
                                                  child: Lottie.asset(
                                                    emojis[i].path,
                                                    height: 50.0,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(),
                          ),
                          (widget.confession.specificIndividuals.isNotEmpty &&
                                  encrypter != null &&
                                  (widget.confession.specificIndividuals
                                          .contains(encrypter!
                                              .encrypt(currentUser.email,
                                                  iv: en.IV
                                                      .fromBase64('campus12'))
                                              .base64) ||
                                      widget.confession.user_uid ==
                                          encrypter!
                                              .encrypt(_auth.currentUser!.uid,
                                                  iv: en.IV
                                                      .fromBase64('campus12'))
                                              .base64))
                              ? Positioned(
                                  right: 0,
                                  bottom:
                                      MediaQuery.of(context).size.height * 0.16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      widget.confession.user_uid ==
                                                  encrypter!
                                                      .encrypt(
                                                          _auth
                                                              .currentUser!.uid,
                                                          iv: en.IV.fromBase64(
                                                              'campus12'))
                                                      .base64 &&
                                              snapshot.data!['seenBySIs']
                                                      .length <
                                                  snapshot
                                                      .data![
                                                          'specificIndividuals']
                                                      .length &&
                                              snapshot.data!['notifyCountSIs'] <
                                                  3
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10.0),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 500),
                                                width: isNotifyContainerExpanded
                                                    ? 340.0
                                                    : 70.0,
                                                curve: Curves.easeInOutBack,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5.0,
                                                        horizontal: 5.0),
                                                decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color.fromARGB(
                                                            255, 227, 41, 28),
                                                        Color.fromARGB(
                                                            255, 212, 80, 71)
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius
                                                        .only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    25.0),
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    25.0)),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Color.fromARGB(
                                                            82, 0, 0, 0),
                                                        blurRadius: 4.0,
                                                        spreadRadius: 1.5,
                                                      )
                                                    ]),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    AnimatedRotation(
                                                      duration: const Duration(
                                                          milliseconds: 1200),
                                                      turns:
                                                          isNotifyContainerExpanded
                                                              ? 0.5
                                                              : 0.0,
                                                      curve:
                                                          Curves.elasticInOut,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          setState(() =>
                                                              isNotifyContainerExpanded =
                                                                  !isNotifyContainerExpanded);
                                                          if (!showNotifyButton) {
                                                            Future.delayed(
                                                                const Duration(
                                                                    milliseconds:
                                                                        450),
                                                                () {
                                                              setState(
                                                                () =>
                                                                    showNotifyButton =
                                                                        true,
                                                              );
                                                            });
                                                          } else {
                                                            setState(
                                                              () =>
                                                                  showNotifyButton =
                                                                      false,
                                                            );
                                                          }
                                                        },
                                                        child:
                                                            Shimmer.fromColors(
                                                          baseColor:
                                                              Colors.white,
                                                          highlightColor:
                                                              Colors.red,
                                                          direction:
                                                              ShimmerDirection
                                                                  .rtl,
                                                          child: const Icon(
                                                            Icons
                                                                .keyboard_double_arrow_left,
                                                            size: 32.0,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    isNotifyContainerExpanded &&
                                                            showNotifyButton
                                                        ? const Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 5.0,
                                                                    right:
                                                                        10.0),
                                                            child: Text(
                                                              "Notify specific individuals",
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 16.0,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ))
                                                        : Container(),
                                                    isNotifyContainerExpanded &&
                                                            showNotifyButton
                                                        ? isNotifyLoading
                                                            ? Container(
                                                                width: 20.0,
                                                                height: 20.0,
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        left:
                                                                            5.0),
                                                                child:
                                                                    const CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2.5,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              )
                                                            : TextButton(
                                                                onPressed:
                                                                    () async {
                                                                  setState(
                                                                    () =>
                                                                        isNotifyLoading =
                                                                            true,
                                                                  );
                                                                  Fluttertoast
                                                                      .showToast(
                                                                    toastLength:
                                                                        Toast
                                                                            .LENGTH_LONG,
                                                                    msg:
                                                                        'This will take a while. Have patience please.',
                                                                    textColor:
                                                                        Colors
                                                                            .white,
                                                                    backgroundColor:
                                                                        const Color.fromARGB(
                                                                            211,
                                                                            0,
                                                                            0,
                                                                            0),
                                                                  );
                                                                  try {
                                                                    final en.Encrypter
                                                                        sharedKeyDecrypter =
                                                                        en.Encrypter(en.RSA(
                                                                            privateKey:
                                                                                widget.privateKey));
                                                                    List<dynamic>
                                                                        encryptedMailList =
                                                                        widget
                                                                            .confession
                                                                            .specificIndividuals;
                                                                    String?
                                                                        decryptedSharedKeyString;
                                                                    for (int i =
                                                                            0;
                                                                        i < widget.confession.encryptedSharedKeys!.length;
                                                                        i++) {
                                                                      try {
                                                                        decryptedSharedKeyString = sharedKeyDecrypter.decrypt(en.Encrypted.fromBase64(widget
                                                                            .confession
                                                                            .encryptedSharedKeys![i]));
                                                                      } catch (err) {}
                                                                    }
                                                                    final decryptedSharedKey = en
                                                                            .Key
                                                                        .fromBase64(
                                                                            decryptedSharedKeyString!);
                                                                    final en.Encrypter
                                                                        contentDecrypter =
                                                                        en.Encrypter(
                                                                            en.AES(decryptedSharedKey));
                                                                    List
                                                                        mailList =
                                                                        [];
                                                                    for (int i =
                                                                            0;
                                                                        i < encryptedMailList.length;
                                                                        i++) {
                                                                      if (!snapshot
                                                                          .data![
                                                                              'seenBySIs']
                                                                          .contains(
                                                                              encryptedMailList[i])) {
                                                                        mailList.add(contentDecrypter.decrypt(
                                                                            en.Encrypted.fromBase64(encryptedMailList[i]),
                                                                            iv: en.IV.fromBase64('campus12')));
                                                                      }
                                                                    }
                                                                    if (mailList
                                                                        .isNotEmpty) {
                                                                      List
                                                                          tokens =
                                                                          await _firestoreMethods
                                                                              .getTokensFromMails(mailList);
                                                                      for (int i =
                                                                              0;
                                                                          i < mailList.length;
                                                                          i++) {
                                                                        //                                                                   await sendMail2(
                                                                        //                                                                     reciever_address:
                                                                        //                                                                         mailList[i],
                                                                        //                                                                     mail_subject:
                                                                        //                                                                         "You've Received a Confession on [Your App's Name]!",
                                                                        //                                                                     mail_content:
                                                                        //                                                                         """
                                                                        // Hello,

                                                                        // Someone has mentioned you in their confession on [Your App's Name]! Open the app and see what they've confessed, and how the community is reacting.

                                                                        // Confession Snippet:
                                                                        // ${widget.confession.confession!.substring(0, (widget.confession.confession!.length * 0.3).toInt())}....

                                                                        // If you haven't installed the app yet, please download it here:
                                                                        // For Android: [Google Play Store link]

                                                                        // Remember, your involvement in the community makes it a better place for everyone. Looking forward to seeing you there!

                                                                        // Best Regards,
                                                                        // [Your Name]
                                                                        // [Your App's Name] Team
                                                                        // """,
                                                                        //                                                                   );
                                                                        Map<dynamic,
                                                                                dynamic>
                                                                            data =
                                                                            {
                                                                          'to': tokens.isNotEmpty && i < tokens.length
                                                                              ? tokens[i]
                                                                              : null,
                                                                          'priority':
                                                                              'high',
                                                                          'data':
                                                                              {
                                                                            'title':
                                                                                'Confessions',
                                                                            'body':
                                                                                "You've recieved a confession!",
                                                                            'type':
                                                                                'toSpecificIndividual',
                                                                            'confession':
                                                                                widget.confession.toJson()
                                                                          }
                                                                        };
                                                                        await http
                                                                            .post(
                                                                          Uri.parse(
                                                                              'https://fcm.googleapis.com/fcm/send'),
                                                                          body:
                                                                              jsonEncode(data),
                                                                          headers: {
                                                                            'Content-Type':
                                                                                'application/json; charset=UTF-8',
                                                                            'Authorization':
                                                                                'key=AAAAtA6V0JA:APA91bEwrE_GBMBe-aWVap09EcR0H9peWaMIY3nM9ewzsxCxjYL9gbBuGPIIPvs-jStFGTMnFI6cq7Lw_bH3yaRuuwymAVppZO1Y6fGI45QgscvFzEfYXHIrn9on6b68y1F59Jg6KweO'
                                                                          },
                                                                        );
                                                                      }
                                                                    }
                                                                    await _firestore
                                                                        .collection(
                                                                            'confessions')
                                                                        .doc(widget
                                                                            .confession
                                                                            .confessionId)
                                                                        .update({
                                                                      'notifyCountSIs':
                                                                          FieldValue.increment(
                                                                              1)
                                                                    });
                                                                    Fluttertoast
                                                                        .showToast(
                                                                      msg:
                                                                          'Successfully notified. You have ${3 - snapshot.data!['notifyCountSIs'] - 1} turns left.',
                                                                      textColor:
                                                                          Colors
                                                                              .white,
                                                                      backgroundColor:
                                                                          const Color.fromARGB(
                                                                              211,
                                                                              0,
                                                                              0,
                                                                              0),
                                                                    );
                                                                  } catch (err) {
                                                                    Fluttertoast
                                                                        .showToast(
                                                                      msg:
                                                                          'Something went wrong. Please try again.',
                                                                      textColor:
                                                                          Colors
                                                                              .white,
                                                                      backgroundColor:
                                                                          const Color.fromARGB(
                                                                              211,
                                                                              0,
                                                                              0,
                                                                              0),
                                                                    );
                                                                  }
                                                                  setState(() =>
                                                                      isNotifyLoading =
                                                                          false);
                                                                },
                                                                style:
                                                                    ButtonStyle(
                                                                  elevation:
                                                                      MaterialStateProperty
                                                                          .all(
                                                                              7.0),
                                                                  padding:
                                                                      MaterialStateProperty
                                                                          .all(
                                                                    const EdgeInsets
                                                                            .symmetric(
                                                                        horizontal:
                                                                            20.0,
                                                                        vertical:
                                                                            9.0),
                                                                  ),
                                                                  backgroundColor:
                                                                      MaterialStateProperty
                                                                          .all(
                                                                    const Color
                                                                            .fromARGB(
                                                                        255,
                                                                        190,
                                                                        29,
                                                                        17),
                                                                  ),
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  'Notify',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            255,
                                                                            255,
                                                                            255),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                    fontSize:
                                                                        17.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                                ),
                                                              )
                                                        : Container(),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : Container(),
                                      widget.confession.enableAnonymousChat
                                          ? AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 500),
                                              width: isChatContainerExpanded
                                                  ? 340.0
                                                  : 70.0,
                                              curve: Curves.easeInOutBack,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5.0,
                                                      horizontal: 5.0),
                                              decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color.fromARGB(
                                                          255, 146, 26, 167),
                                                      Color.fromARGB(
                                                          255, 206, 84, 227)
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  25.0),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  25.0)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color.fromARGB(
                                                          82, 0, 0, 0),
                                                      blurRadius: 4.0,
                                                      spreadRadius: 1.5,
                                                    )
                                                  ]),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  AnimatedRotation(
                                                    duration: const Duration(
                                                        milliseconds: 1200),
                                                    turns:
                                                        isChatContainerExpanded
                                                            ? 0.5
                                                            : 0.0,
                                                    curve: Curves.elasticInOut,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() =>
                                                            isChatContainerExpanded =
                                                                !isChatContainerExpanded);
                                                        if (!showChatButton) {
                                                          Future.delayed(
                                                              const Duration(
                                                                  milliseconds:
                                                                      450), () {
                                                            setState(
                                                              () =>
                                                                  showChatButton =
                                                                      true,
                                                            );
                                                          });
                                                        } else {
                                                          setState(
                                                            () =>
                                                                showChatButton =
                                                                    false,
                                                          );
                                                        }
                                                      },
                                                      child: Shimmer.fromColors(
                                                        baseColor: Colors.white,
                                                        highlightColor:
                                                            Colors.purple,
                                                        direction:
                                                            ShimmerDirection
                                                                .rtl,
                                                        child: const Icon(
                                                          Icons
                                                              .keyboard_double_arrow_left,
                                                          size: 32.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  isChatContainerExpanded &&
                                                          showChatButton
                                                      ? Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 5.0,
                                                                  right: 10.0),
                                                          child: widget
                                                                      .confession
                                                                      .user_uid ==
                                                                  encrypter!
                                                                      .encrypt(
                                                                          _auth
                                                                              .currentUser!
                                                                              .uid,
                                                                          iv: en
                                                                              .IV
                                                                              .fromBase64('campus12'))
                                                                      .base64
                                                              ? const Text(
                                                                  "Anonymous chat enabled",
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        17.0,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                )
                                                              : const Text(
                                                                  'Want to chat privately?',
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        17.0,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                        )
                                                      : Container(),
                                                  isChatContainerExpanded &&
                                                          showChatButton
                                                      ? isChatLoading
                                                          ? Container(
                                                              width: 20.0,
                                                              height: 20.0,
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      left:
                                                                          5.0),
                                                              child:
                                                                  const CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2.5,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            )
                                                          : TextButton(
                                                              onPressed:
                                                                  () async {
                                                                if (await checkConnectivity()) {
                                                                  try {
                                                                    DocumentSnapshot confessionDoc = await _firestore
                                                                        .collection(
                                                                            'confessions')
                                                                        .doc(widget
                                                                            .confession
                                                                            .confessionId)
                                                                        .get();
                                                                    if (widget
                                                                            .confession
                                                                            .user_uid ==
                                                                        encrypter!
                                                                            .encrypt(currentUser.uid,
                                                                                iv: en.IV.fromBase64('campus12'))
                                                                            .base64) {
                                                                      showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (context) {
                                                                          return MediaQuery(
                                                                            data:
                                                                                MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                                                                            child:
                                                                                SimpleDialog(
                                                                              title: Text(
                                                                                'Chat Rooms',
                                                                                style: TextStyle(
                                                                                  fontSize: 18.0,
                                                                                  fontWeight: FontWeight.w500,
                                                                                  color: const Color.fromARGB(255, 61, 61, 61),
                                                                                ),
                                                                              ),
                                                                              children: specificIndividualMailsToIDs //come here
                                                                                          .length >
                                                                                      0
                                                                                  ? specificIndividualMailsToIDs.keys
                                                                                      .toList()
                                                                                      .map(
                                                                                        (email) => SimpleDialogOption(
                                                                                          onPressed: () async {
                                                                                            setState(
                                                                                              () {
                                                                                                showChatButton = false;
                                                                                                isChatContainerExpanded = false;
                                                                                              },
                                                                                            );
                                                                                            DocumentSnapshot<Map<String, dynamic>> distantUserSnap = await _firestore.collection('users').doc(specificIndividualMailsToIDs[email]!).get();
                                                                                            RSAPublicKey distantUserPublicKey = RSAPublicKey(BigInt.parse(distantUserSnap['public_key_modulus']), BigInt.parse(distantUserSnap['public_key_exponent']));
                                                                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => Chatt(confession: widget.confession, sharedKeyEncrypter: encrypter!, currentUserPrivateKey: widget.privateKey!, distantUserPublicKey: distantUserPublicKey, avatarURL: widget.confession.avatarURL, documentid: widget.confession.chatRoomIDs[encrypter!.encrypt(specificIndividualMailsToIDs[email]!, iv: en.IV.fromBase64('campus12')).base64], uid: currentUser.uid, distantuid: specificIndividualMailsToIDs[email]!)));
                                                                                          },
                                                                                          child: Text(
                                                                                            email,
                                                                                            style: TextStyle(
                                                                                              fontSize: 18.0,
                                                                                              fontWeight: FontWeight.w500,
                                                                                              color: const Color.fromARGB(255, 61, 61, 61),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      )
                                                                                      .toList()
                                                                                  : [
                                                                                      SimpleDialogOption(
                                                                                        child: Text('No chats to show here'),
                                                                                      )
                                                                                    ],
                                                                            ),
                                                                          );
                                                                        },
                                                                      );
                                                                    } else {
                                                                      setState(
                                                                        () => isChatLoading =
                                                                            true,
                                                                      );
                                                                      if (encrypter !=
                                                                              null &&
                                                                          confessionDoc['chatRoomIDs']
                                                                              .keys
                                                                              .toList()
                                                                              .contains(encrypter!.encrypt(_auth.currentUser!.uid, iv: en.IV.fromBase64('campus12')).base64)) {
                                                                        DocumentSnapshot<
                                                                            Map<String,
                                                                                dynamic>> ownerSnap = await _firestore
                                                                            .collection(
                                                                                'users')
                                                                            .doc(encrypter!.decrypt(en.Encrypted.fromBase64(widget.confession.user_uid),
                                                                                iv: en.IV.fromBase64('campus12')))
                                                                            .get();
                                                                        RSAPublicKey
                                                                            distantUserPublicKey =
                                                                            RSAPublicKey(BigInt.parse(ownerSnap['public_key_modulus']),
                                                                                BigInt.parse(ownerSnap['public_key_exponent']));
                                                                        Navigator.of(context).push(MaterialPageRoute(builder:
                                                                            (context) {
                                                                          return Chatt(
                                                                              confession: widget.confession,
                                                                              sharedKeyEncrypter: encrypter!,
                                                                              currentUserPrivateKey: widget.privateKey!,
                                                                              distantUserPublicKey: distantUserPublicKey,
                                                                              avatarURL: widget.confession.avatarURL,
                                                                              documentid: confessionDoc['chatRoomIDs'][encrypter!.encrypt(_auth.currentUser!.uid, iv: en.IV.fromBase64('campus12')).base64],
                                                                              uid: currentUser.uid,
                                                                              distantuid: encrypter!.decrypt(en.Encrypted.fromBase64(widget.confession.user_uid), iv: en.IV.fromBase64('campus12')));
                                                                        }));
                                                                      } else {
                                                                        try {
                                                                          String room_id = await createchatroomid(
                                                                              currentUser.uid,
                                                                              encrypter!.decrypt(en.Encrypted.fromBase64(widget.confession.user_uid), iv: en.IV.fromBase64('campus12')),
                                                                              encrypter!);
                                                                          if (room_id ==
                                                                              'Some error occurred') {
                                                                            Fluttertoast.showToast(
                                                                              msg: 'Some error occurred. Please try again.',
                                                                              textColor: Colors.white,
                                                                              backgroundColor: const Color.fromARGB(211, 0, 0, 0),
                                                                            );
                                                                          } else {
                                                                            Map<String, dynamic>
                                                                                chatRoomIDs =
                                                                                widget.confession.chatRoomIDs;
                                                                            chatRoomIDs[encrypter!.encrypt(_auth.currentUser!.uid, iv: en.IV.fromBase64('campus12')).base64] =
                                                                                room_id;
                                                                            await _firestore.collection('confessions').doc(widget.confession.confessionId).update({
                                                                              'chatRoomIDs': chatRoomIDs
                                                                            });
                                                                            DocumentSnapshot<Map<String, dynamic>>
                                                                                ownerSnap =
                                                                                await _firestore.collection('users').doc(encrypter!.decrypt(en.Encrypted.fromBase64(widget.confession.user_uid), iv: en.IV.fromBase64('campus12'))).get();
                                                                            RSAPublicKey
                                                                                distantUserPublicKey =
                                                                                RSAPublicKey(BigInt.parse(ownerSnap['public_key_modulus']), BigInt.parse(ownerSnap['public_key_exponent']));
                                                                            Navigator.of(context).push(
                                                                              MaterialPageRoute(
                                                                                builder: (context) => Chatt(confession: widget.confession, sharedKeyEncrypter: encrypter!, currentUserPrivateKey: widget.privateKey!, distantUserPublicKey: distantUserPublicKey, avatarURL: widget.confession.avatarURL, documentid: room_id, uid: currentUser.uid, distantuid: encrypter!.decrypt(en.Encrypted.fromBase64(widget.confession.user_uid), iv: en.IV.fromBase64('campus12'))),
                                                                              ),
                                                                            );
                                                                          }
                                                                        } catch (err) {
                                                                          setState(
                                                                            () =>
                                                                                isChatLoading = false,
                                                                          );
                                                                        }
                                                                      }
                                                                    }
                                                                    setState(
                                                                        () {
                                                                      isChatLoading =
                                                                          false;
                                                                      showChatButton =
                                                                          false;
                                                                      isChatContainerExpanded =
                                                                          false;
                                                                    });
                                                                  } catch (err) {
                                                                    setState(
                                                                      () => isChatLoading =
                                                                          false,
                                                                    );
                                                                  }
                                                                } else {
                                                                  Fluttertoast
                                                                      .showToast(
                                                                    msg:
                                                                        'Some error occurred. Please try again.',
                                                                    textColor:
                                                                        Colors
                                                                            .white,
                                                                    backgroundColor:
                                                                        const Color.fromARGB(
                                                                            211,
                                                                            0,
                                                                            0,
                                                                            0),
                                                                  );
                                                                }
                                                              },
                                                              style:
                                                                  ButtonStyle(
                                                                elevation:
                                                                    MaterialStateProperty
                                                                        .all(
                                                                            7.0),
                                                                padding:
                                                                    MaterialStateProperty
                                                                        .all(
                                                                  const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          20.0,
                                                                      vertical:
                                                                          9.0),
                                                                ),
                                                                backgroundColor:
                                                                    MaterialStateProperty
                                                                        .all(
                                                                  const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      138,
                                                                      0,
                                                                      163),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                'Chat',
                                                                style:
                                                                    TextStyle(
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          255,
                                                                          255,
                                                                          255),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  fontSize:
                                                                      20.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                              ),
                                                            )
                                                      : Container(),
                                                ],
                                              ),
                                            )
                                          : Container(),
                                    ],
                                  ),
                                )
                              : Container()
                        ],
                      ),
                    );
                  }
                },
              ),
      ),
    );
  }
}
