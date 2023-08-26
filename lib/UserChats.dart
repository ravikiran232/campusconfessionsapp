import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/UserProfile.dart';
import 'package:untitled2/user_provider.dart';
import 'confession_cardII.dart';
import 'confession_home_page.dart';
import 'models.dart' as Models;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class UserChatsPage extends StatefulWidget {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> confessions;
  int currentIndex;
  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> chatSnapshot;
  bool didChangeAvatarURL;
  UserChatsPage(
      {super.key,
      required this.publicKey,
      required this.privateKey,
      required this.confessions,
      required this.currentIndex,
      required this.chatSnapshot,
      required this.didChangeAvatarURL});

  @override
  State<UserChatsPage> createState() => _UserChatsPageState();
}

class _UserChatsPageState extends State<UserChatsPage> {
  String indicator = 'active';

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // initialize in initState
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Models.User currentUser = Provider.of<UserProvider>(context).getUser!;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(239, 254, 254, 254),
        appBar: AppBar(
          elevation: 0.0,
          titleSpacing: 0.0,
          leading: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.lightBlue, Colors.lightBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)),
            child: IconButton(
              onPressed: () {
                widget.didChangeAvatarURL
                    ? Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ConfessionHomePage(),
                        ),
                      )
                    : Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back,
                size: 32.0,
                color: Color.fromARGB(255, 249, 249, 249),
              ),
            ),
          ),
          title: Container(
            height: 57.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.lightBlue, Color.fromARGB(255, 26, 123, 203)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
            ),
            child: Row(
              children: [
                Text(
                  'My Chats',
                  style: GoogleFonts.secularOne(
                    textStyle: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 249, 249, 249),
                        letterSpacing: 0.5),
                  ),
                ),
                Flexible(child: Container()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => UserProfile(
                          publicKey: widget.publicKey,
                          privateKey: widget.privateKey,
                          currentIndex: widget.currentIndex,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.person,
                      size: 30.0,
                      color: Color.fromARGB(255, 249, 249, 249),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              height: 45.0,
              //height: MediaQuery.of(context).size.height * 0.06,
              padding: const EdgeInsets.only(bottom: 0.0, top: 5.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color.fromARGB(255, 20, 175, 247),
                  Color.fromARGB(255, 26, 123, 203),
                ], begin: Alignment.centerLeft, end: Alignment.centerRight),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10.0,
                    spreadRadius: 4.0,
                    color: Colors.grey,
                  )
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => indicator = 'active');
                          _pageController.animateToPage(0,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.linear);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 7.0),
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Text(
                            'Active',
                            style: GoogleFonts.secularOne(
                              textStyle: const TextStyle(
                                fontSize: 17.0,
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 249, 249, 249),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => indicator = 'ended');
                          _pageController.animateToPage(1,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.linear);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 7.0),
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Text(
                            'Ended',
                            style: GoogleFonts.secularOne(
                              textStyle: const TextStyle(
                                fontSize: 17.0,
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 249, 249, 249),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 150),
                    left: indicator == 'active'
                        ? 0.0
                        : MediaQuery.of(context).size.width * 0.5,
                    child: Container(
                      height: 40.0,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2.5),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Flexible(
              child: widget.confessions == null
                  ? const Center(
                      child: Text('Please check your internet connection.'),
                    )
                  : PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (index == 0) {
                          setState(
                            () => indicator = 'active',
                          );
                        } else {
                          setState(
                            () => indicator = 'ended',
                          );
                        }
                      },
                      children: [
                        Builder(builder: (context) {
                          List userChats = widget.confessions.where((element) {
                            String? confessionSharedKey;
                            en.Encrypter? encrypter;
                            final en.Encrypter decrypter = en.Encrypter(
                                en.RSA(privateKey: widget.privateKey));
                            for (int i = 0;
                                i < element.get('encryptedSharedKeys').length;
                                i++) {
                              try {
                                confessionSharedKey = decrypter.decrypt(
                                    en.Encrypted.fromBase64(
                                        element.get('encryptedSharedKeys')[i]));
                                encrypter = en.Encrypter(en.AES(
                                    en.Key.fromBase64(confessionSharedKey)));
                              } catch (err) {}
                            }
                            if (confessionSharedKey != null &&
                                encrypter != null &&
                                element.get('chatRoomIDs').containsKey(encrypter
                                    .encrypt(currentUser.uid,
                                        iv: en.IV.fromBase64('campus12'))
                                    .base64) &&
                                widget.chatSnapshot.data!.docs
                                        .where((doc) =>
                                            doc.id ==
                                            element.get('chatRoomIDs')[
                                                encrypter!
                                                    .encrypt(currentUser.uid,
                                                        iv: en.IV.fromBase64(
                                                            'campus12'))
                                                    .base64])
                                        .toList()[0]['endchat'] ==
                                    false) {
                              return true;
                            } else if (confessionSharedKey != null &&
                                encrypter != null &&
                                element.get('user_uid') ==
                                    encrypter
                                        .encrypt(currentUser.uid,
                                            iv: en.IV.fromBase64('campus12'))
                                        .base64 &&
                                element.get('chatRoomIDs').length > 0 &&
                                widget.chatSnapshot.data!.docs
                                    .where((doc) => element
                                        .get('chatRoomIDs')
                                        .containsValue(doc.id))
                                    .toList()
                                    .any((doc) => doc['endchat'] == false)) {
                              return true;
                            } else {
                              return false;
                            }
                          }).toList();
                          if (userChats.isEmpty) {
                            return const Center(
                              child: Text("No chats to show here"),
                            );
                          } else {
                            return ListView.builder(
                                itemCount: userChats.length,
                                itemBuilder: (context, index) {
                                  return ConfessionCardII(
                                    publicKey: widget.publicKey,
                                    privateKey: widget.privateKey,
                                    enablePageView: false,
                                    confessions: widget.confessions!,
                                    currentIndex: index,
                                    specificConfessions: userChats,
                                  );
                                });
                          }
                        }),
                        Builder(
                          builder: (context) {
                            List chatsForMe =
                                widget.confessions.where((element) {
                              String? confessionSharedKey;
                              en.Encrypter? encrypter;
                              final en.Encrypter decrypter = en.Encrypter(
                                  en.RSA(privateKey: widget.privateKey));
                              for (int i = 0;
                                  i < element.get('encryptedSharedKeys').length;
                                  i++) {
                                try {
                                  confessionSharedKey = decrypter.decrypt(
                                      en.Encrypted.fromBase64(element
                                          .get('encryptedSharedKeys')[i]));
                                  encrypter = en.Encrypter(en.AES(
                                      en.Key.fromBase64(confessionSharedKey)));
                                } catch (err) {}
                              }
                              if (confessionSharedKey != null &&
                                  encrypter != null &&
                                  element.get('chatRoomIDs').containsKey(encrypter
                                      .encrypt(currentUser.uid,
                                          iv: en.IV.fromBase64('campus12'))
                                      .base64) &&
                                  widget.chatSnapshot.data!.docs
                                          .where((doc) =>
                                              doc.id ==
                                              element.get('chatRoomIDs')[
                                                  encrypter!
                                                      .encrypt(currentUser.uid,
                                                          iv: en.IV.fromBase64(
                                                              'campus12'))
                                                      .base64])
                                          .toList()[0]['endchat'] ==
                                      true) {
                                return true;
                              } else if (confessionSharedKey != null &&
                                  encrypter != null &&
                                  element.get('user_uid') ==
                                      encrypter
                                          .encrypt(currentUser.uid,
                                              iv: en.IV.fromBase64('campus12'))
                                          .base64 &&
                                  element.get('chatRoomIDs').length > 0 &&
                                  widget.chatSnapshot.data!.docs
                                      .where((doc) =>
                                          element.get('chatRoomIDs').containsValue(doc.id))
                                      .toList()
                                      .any((doc) => doc['endchat'] == true)) {
                                return true;
                              } else {
                                return false;
                              }
                            }).toList();
                            if (chatsForMe.isEmpty) {
                              return const Center(
                                child: Text("No chats to show here"),
                              );
                            } else {
                              return ListView.builder(
                                itemCount: chatsForMe.length,
                                itemBuilder: (context, index) {
                                  return ConfessionCardII(
                                    publicKey: widget.publicKey,
                                    privateKey: widget.privateKey,
                                    enablePageView: false,
                                    confessions: widget.confessions!,
                                    currentIndex: index,
                                    specificConfessions: chatsForMe,
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
            )
          ],
        ),
      ),
    );
  }
}
