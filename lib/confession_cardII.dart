import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:untitled2/ConfessionPageView.dart';
import 'package:untitled2/PollCard.dart';
import 'package:untitled2/firestore_methods.dart';
import 'package:untitled2/models.dart' as Models;
import 'package:untitled2/new_card_widget.dart';
import 'package:untitled2/user_confession_page.dart';
import 'package:untitled2/vote_clipper.dart';
import 'package:intl/intl.dart';
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

// ignore: must_be_immutable
class ConfessionCardII extends StatefulWidget {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  bool isNew;
  bool showNewCard;
  bool tapped = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> confessions;
  int currentIndex;
  bool enablePageView;
  int rank;
  List specificConfessions;
  ConfessionCardII({
    super.key,
    required this.publicKey,
    required this.privateKey,
    this.isNew = false,
    this.showNewCard = false,
    required this.confessions,
    required this.currentIndex,
    this.enablePageView = true,
    this.specificConfessions = const [],
    this.rank = -1,
  });

  @override
  State<ConfessionCardII> createState() => _ConfessionCardIIState();
}

class _ConfessionCardIIState extends State<ConfessionCardII> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreMethods _firestoreMethods = FirestoreMethods();

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

  String? confessionSharedKey;
  en.Encrypter? encrypter;

  Models.Confession? currentConfession;

  @override
  void initState() {
    super.initState();
    currentConfession = Models.Confession(
            enablePoll: false, poll: null, notifyCountSIs: 0, adminPost: false)
        .toConfessionModel(widget.enablePageView
            ? widget.confessions[widget.currentIndex]
            : widget.specificConfessions[widget.currentIndex]);

    final en.Encrypter decrypter =
        en.Encrypter(en.RSA(privateKey: widget.privateKey));
    for (int i = 0; i < currentConfession!.encryptedSharedKeys!.length; i++) {
      try {
        confessionSharedKey = decrypter.decrypt(en.Encrypted.fromBase64(
            currentConfession!.encryptedSharedKeys![i]));
        encrypter =
            en.Encrypter(en.AES(en.Key.fromBase64(confessionSharedKey!)));
      } catch (err) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      child: AnimatedScale(
        scale: widget.tapped ? 0.90 : 1,
        duration: const Duration(milliseconds: 100),
        child: ElevatedButton(
          onPressed: () async {
            setState(() {
              widget.tapped = true;
            });
            await Future.delayed(const Duration(milliseconds: 40));
            if (widget.enablePageView) {
              Navigator.push(
                context,
                PageTransition(
                    child: ConfessionPageView(
                      publicKey: widget.publicKey,
                      privateKey: widget.privateKey,
                      confessions: widget.confessions,
                      currentIndex: widget.currentIndex,
                    ),
                    type: PageTransitionType.fade),
              );
            } else {
              Models.Confession currentConfession = Models.Confession(
                      enablePoll: false,
                      poll: null,
                      notifyCountSIs: 0,
                      adminPost: false)
                  .toConfessionModel(
                      widget.specificConfessions[widget.currentIndex]);
              Navigator.push(
                context,
                PageTransition(
                  child: UserConfessionPage(
                    publicKey: widget.publicKey,
                    privateKey: widget.privateKey,
                    confession: currentConfession,
                    avatarURL: currentConfession.avatarURL,
                    firstTime: widget.showNewCard,
                  ),
                  type: PageTransitionType.fade,
                ),
              );
            }
            setState(() {
              widget.tapped = false;
            });
            await _firestoreMethods.viewedConfession(
                currentConfession!, encrypter);
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white),
            elevation: MaterialStateProperty.all(10.0),
            padding: MaterialStateProperty.all(EdgeInsets.zero),
            shape: MaterialStateProperty.all(
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(20.0),
                ),
              ),
            ),
          ),
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              Row(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height < 630.0
                        ? MediaQuery.of(context).size.height * 0.21
                        : MediaQuery.of(context).size.height < 710.0
                            ? MediaQuery.of(context).size.height * 0.19
                            : MediaQuery.of(context).size.height * 0.172,
                    width: MediaQuery.of(context).size.width * 0.12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentConfession!.adminPost
                            ? [
                                //Colors.amber,
                                const Color.fromARGB(255, 236, 178, 6),
                                const Color.fromARGB(255, 236, 178, 6),
                              ]
                            : (encrypter != null &&
                                    currentConfession!.specificIndividuals
                                        .contains(encrypter!
                                            .encrypt(_auth.currentUser!.email!,
                                                iv: en.IV
                                                    .fromBase64('campus12'))
                                            .base64))
                                ? [
                                    const Color.fromARGB(255, 237, 85, 75),
                                    Colors.red,
                                    const Color.fromARGB(255, 194, 52, 42),
                                  ]
                                : (encrypter != null &&
                                        currentConfession!.user_uid ==
                                            encrypter!
                                                .encrypt(_auth.currentUser!.uid,
                                                    iv: en.IV
                                                        .fromBase64('campus12'))
                                                .base64)
                                    ? [
                                        const Color.fromARGB(
                                            255, 165, 165, 165),
                                        const Color.fromARGB(
                                            255, 161, 161, 161),
                                        const Color.fromARGB(
                                            255, 123, 123, 123),
                                      ]
                                    : [
                                        const Color.fromARGB(255, 87, 163, 226),
                                        Colors.lightBlue,
                                        const Color.fromARGB(255, 11, 136, 237),
                                      ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        bottomLeft: Radius.circular(18.0),
                      ),
                    ),
                    child: Transform.rotate(
                      angle: -1.5707963267948966,
                      child: OverflowBox(
                        minWidth: 0.0,
                        minHeight: 0.0,
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: Row(
                          children: [
                            currentConfession!.adminPost
                                ? Padding(
                                    padding: EdgeInsets.only(
                                        right:
                                            MediaQuery.of(context).size.height *
                                                0.01,
                                        left:
                                            MediaQuery.of(context).size.height *
                                                0.025),
                                    child: Text(
                                      'Admin',
                                      style: GoogleFonts.secularOne(
                                        textStyle: const TextStyle(
                                          fontSize: 19.0,
                                          fontWeight: FontWeight.w500,
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                        ),
                                      ),
                                    ),
                                  )
                                : confessionSharedKey == null
                                    ? Padding(
                                        padding: EdgeInsets.only(
                                            right: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.0,
                                            left: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01),
                                        child: Text(
                                          'Anonymous',
                                          style: GoogleFonts.secularOne(
                                            textStyle: const TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w500,
                                              color: Color.fromARGB(
                                                  255, 255, 255, 255),
                                            ),
                                          ),
                                        ),
                                      )
                                    : (currentConfession!.specificIndividuals
                                            .contains(encrypter!
                                                .encrypt(
                                                    _auth.currentUser!.email!,
                                                    iv: en.IV
                                                        .fromBase64('campus12'))
                                                .base64))
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                right: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.01,
                                                left: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.025),
                                            child: Text(
                                              'For You',
                                              style: GoogleFonts.secularOne(
                                                textStyle: const TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color.fromARGB(
                                                      255, 255, 255, 255),
                                                ),
                                              ),
                                            ),
                                          )
                                        : (currentConfession!.user_uid ==
                                                encrypter!
                                                    .encrypt(
                                                        _auth.currentUser!.uid,
                                                        iv: en.IV.fromBase64(
                                                            'campus12'))
                                                    .base64)
                                            ? Padding(
                                                padding: EdgeInsets.only(
                                                    left: MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.023,
                                                    right:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.001),
                                                child: Text(
                                                  'Personal',
                                                  style: GoogleFonts.secularOne(
                                                    textStyle: const TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Padding(
                                                padding: EdgeInsets.only(
                                                    right:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.0,
                                                    left: MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.01),
                                                child: Text(
                                                  'Anonymous',
                                                  style: GoogleFonts.secularOne(
                                                    textStyle: const TextStyle(
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                    ),
                                                  ),
                                                ),
                                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0, vertical: 5.0),
                              child: Transform.rotate(
                                angle: 1.5707963267948966,
                                child: CircleAvatar(
                                  radius: 16.5,
                                  backgroundColor:
                                      const Color.fromARGB(0, 255, 255, 255),
                                  backgroundImage: const AssetImage(
                                      'assets/images/default_avatar.jpg'),
                                  child: Hero(
                                    tag: currentConfession!.confessionId!,
                                    child: CircleAvatar(
                                      radius: 16.5,
                                      backgroundColor: const Color.fromARGB(
                                          0, 255, 255, 255),
                                      backgroundImage: currentConfession!
                                                  .avatarURL ==
                                              'default'
                                          ? const AssetImage(
                                                  'assets/images/default_avatar.jpg')
                                              as ImageProvider
                                          : (encrypter != null &&
                                                  currentConfession!.user_uid ==
                                                      encrypter!
                                                          .encrypt(
                                                              _auth.currentUser!
                                                                  .uid,
                                                              iv: en.IV
                                                                  .fromBase64(
                                                                      'campus12'))
                                                          .base64)
                                              ? NetworkImage(
                                                  _auth.currentUser!.photoURL!)
                                              : NetworkImage(
                                                  currentConfession!.avatarURL),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                        height: MediaQuery.of(context).size.height < 630.0
                            ? MediaQuery.of(context).size.height * 0.21
                            : MediaQuery.of(context).size.height < 710.0
                                ? MediaQuery.of(context).size.height * 0.19
                                : MediaQuery.of(context).size.height * 0.172,
                        padding: EdgeInsets.only(
                            top: 0.0,
                            left: MediaQuery.of(context).size.width * 0.01,
                            right: MediaQuery.of(context).size.width * 0.02,
                            bottom: MediaQuery.of(context).size.height * 0.002),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20.0),
                            bottomRight: Radius.circular(20.0),
                          ),
                          border: Border(
                              top: BorderSide(
                                  color: Color.fromARGB(255, 179, 179, 179),
                                  width: 1.0),
                              right: BorderSide(
                                  color: Color.fromARGB(255, 179, 179, 179),
                                  width: 1.0),
                              bottom: BorderSide(
                                  color: Color.fromARGB(255, 179, 179, 179),
                                  width: 1.0),
                              left: BorderSide(
                                  color: Color.fromARGB(255, 179, 179, 179),
                                  width: 1.0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 2.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '#${currentConfession!.confession_no.toString()}',
                                    style: GoogleFonts.caveat(
                                      textStyle: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w900,
                                        color: Color.fromARGB(255, 66, 66, 66),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(),
                                  ),
                                  widget.confessions[widget.currentIndex]
                                          ['enablePoll']
                                      ? const Padding(
                                          padding: EdgeInsets.only(right: 10.0),
                                          child: PollCard(),
                                        )
                                      : Container(),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 5.0,
                                    ),
                                    child: Text(
                                      DateFormat.yMd().format(
                                        currentConfession!.datePublished!
                                            .toDate(),
                                      ),
                                      style: const TextStyle(
                                          color:
                                              Color.fromARGB(255, 90, 90, 90),
                                          fontSize: 11.0),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 4.0,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 3.0),
                              child: Text(
                                currentConfession!.confession!,
                                style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 4,
                              ),
                            ),
                            Flexible(child: Container()),
                            Row(
                              children: [
                                Text(
                                  currentConfession!.upvotes.length.toString(),
                                  style: GoogleFonts.secularOne(
                                    textStyle: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w100,
                                      color: currentConfession!.upvotes
                                              .contains(_auth.currentUser!.uid)
                                          ? Colors.green
                                          : const Color.fromARGB(
                                              255, 90, 90, 90),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0.0, -1.0),
                                  child: Transform.scale(
                                    scale: 0.65,
                                    child: VoteClipper(
                                      color: Colors.green,
                                      icon_height:
                                          MediaQuery.of(context).size.height *
                                              0.025,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5.0,
                                ),
                                Text(
                                  currentConfession!.downvotes.length
                                      .toString(),
                                  style: GoogleFonts.secularOne(
                                    textStyle: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w100,
                                      color: currentConfession!.downvotes
                                              .contains(_auth.currentUser!.uid)
                                          ? Colors.red
                                          : const Color.fromARGB(
                                              255, 90, 90, 90),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, 0.0),
                                  child: Transform.scale(
                                    scale: 0.66,
                                    child: Transform.rotate(
                                      angle: 1.5707963267948966 * 2,
                                      child: VoteClipper(
                                        color: Colors.red,
                                        icon_height:
                                            MediaQuery.of(context).size.height *
                                                0.025,
                                      ),
                                    ),
                                  ),
                                ),
                                Flexible(child: Container()),
                                Text(
                                  '${currentConfession!.reactions['like'].length + currentConfession!.reactions['love'].length + currentConfession!.reactions['haha'].length + currentConfession!.reactions['wink'].length + currentConfession!.reactions['woah'].length + currentConfession!.reactions['sad'].length + currentConfession!.reactions['angry'].length} Reactions',
                                  style: GoogleFonts.secularOne(
                                    textStyle: const TextStyle(
                                      fontSize: 14.0,
                                      color: Color.fromARGB(255, 61, 61, 61),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 9.0,
                                ),
                                Text(
                                  '${currentConfession!.views.length} views',
                                  style: GoogleFonts.secularOne(
                                    textStyle: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w100,
                                      color: Color.fromARGB(255, 61, 61, 61),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )),
                  ),
                ],
              ),
              !currentConfession!.views.contains(_auth.currentUser!.uid) &&
                      widget.showNewCard
                  ? const Positioned(
                      top: -0.1,
                      right: 25.0,
                      child: NewCard(),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
