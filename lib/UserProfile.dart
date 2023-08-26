import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/UserChats.dart';
import 'package:untitled2/confession_cardII.dart';
import 'package:untitled2/confession_home_page.dart';
import 'package:untitled2/storage_methods.dart';
import 'models.dart' as Models;
import 'user_provider.dart';
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class UserProfile extends StatefulWidget {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  int currentIndex;
  UserProfile(
      {super.key,
      required this.currentIndex,
      required this.publicKey,
      required this.privateKey});
  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String indicator = 'MyConfessions';

  final PageController _pageController = PageController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageMethods _storageMethods = StorageMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool changingAvatar = false;

  bool didChangeAvatarURL = false;

  List<String> maleImagePaths = [
    'assets/images/avatars/man1.png',
    'assets/images/avatars/man2.png',
    'assets/images/avatars/man3.png',
    'assets/images/avatars/man4.png',
    'assets/images/avatars/man5.png',
    'assets/images/avatars/man6.png',
    'assets/images/avatars/man7.png',
    'assets/images/avatars/man8.png',
    'assets/images/avatars/man9.png',
    'assets/images/avatars/man10.png',
    'assets/images/avatars/man11.png',
    'assets/images/avatars/man12.jpeg'
  ];

  List<String> femaleImagePaths = [
    'assets/images/avatars/woman1.png',
    'assets/images/avatars/woman2.png',
    'assets/images/avatars/woman3.png',
    'assets/images/avatars/woman4.png',
    'assets/images/avatars/woman5.png',
    'assets/images/avatars/woman6.png',
    'assets/images/avatars/woman7.png',
    'assets/images/avatars/woman8.png',
    'assets/images/avatars/woman9.png',
    'assets/images/avatars/woman10.png',
    'assets/images/avatars/woman11.png',
    'assets/images/avatars/woman12.png',
  ];

  @override
  void initState() {
    super.initState();
    _getData();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  QuerySnapshot<Map<String, dynamic>>? confession_snapshot;

  void _getData() async {
    confession_snapshot = await _firestore.collection('confessions').get();
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

  Future<void> changeAvatar(bool isMale, int index) async {
    if (await checkConnectivity()) {
      try {
        ByteData bytes = await rootBundle
            .load(isMale ? maleImagePaths[index] : femaleImagePaths[index]);
        Uint8List byteList = bytes.buffer.asUint8List();
        String newAvatarURL = await _storageMethods.uploadImageToStorage(
            'Avatars', _auth.currentUser!.uid, byteList);
        await _auth.currentUser!.updatePhotoURL(newAvatarURL);
      } catch (err) {
        Fluttertoast.showToast(
          msg: 'Unable to change avatar. Please try again.',
          textColor: Colors.white,
          backgroundColor: const Color.fromARGB(211, 0, 0, 0),
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Please check your internet connection.',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Models.User currentUser = Provider.of<UserProvider>(context).getUser!;
    if (confession_snapshot == null) {
      return const Center(
        child: Text('Empty.'),
      );
    }
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
              onPressed: () => {
                didChangeAvatarURL
                    ? Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ConfessionHomePage(),
                        ),
                      )
                    : Navigator.of(context).pop()
              },
              icon: const Icon(
                Icons.arrow_back,
                size: 30.0,
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
                  'My Profile',
                  style: GoogleFonts.secularOne(
                    textStyle: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 249, 249, 249),
                        letterSpacing: 0.5),
                  ),
                ),
                Flexible(child: Container()),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(textScaleFactor: 1.0),
                          child: Dialog(
                            child: PageView(
                              controller: _pageController,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 10.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Change your avatar',
                                            style: TextStyle(
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          Flexible(child: Container()),
                                          InkWell(
                                            onTap: () {
                                              _pageController.animateToPage(1,
                                                  duration: const Duration(
                                                      milliseconds: 150),
                                                  curve: Curves.linear);
                                            },
                                            child: const Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Female',
                                                  style: TextStyle(
                                                      fontSize: 13.0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  size: 15.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: RawScrollbar(
                                          thickness: 2.0,
                                          thumbColor: const Color.fromARGB(
                                              148, 0, 0, 0),
                                          child: GridView.count(
                                            crossAxisCount: 2,
                                            children: List.generate(
                                              maleImagePaths.length,
                                              (index) {
                                                return InkWell(
                                                  onTap: () async {
                                                    Navigator.of(context).pop();
                                                    setState(
                                                      () =>
                                                          changingAvatar = true,
                                                    );
                                                    await changeAvatar(
                                                        true, index);
                                                    setState(() {
                                                      changingAvatar = false;
                                                      didChangeAvatarURL = true;
                                                      currentUser.avatarURL =
                                                          _auth.currentUser!
                                                              .photoURL!;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 10.0),
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.white,
                                                      backgroundImage:
                                                          AssetImage(
                                                        maleImagePaths[index],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 10.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              _pageController.animateToPage(0,
                                                  duration: const Duration(
                                                      milliseconds: 150),
                                                  curve: Curves.linear);
                                            },
                                            child: const Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.arrow_back,
                                                  size: 15.0,
                                                ),
                                                Text(
                                                  'Male',
                                                  style: TextStyle(
                                                      fontSize: 13.0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Flexible(child: Container()),
                                        ],
                                      ),
                                      Expanded(
                                        child: RawScrollbar(
                                          thickness: 2.0,
                                          thumbColor: const Color.fromARGB(
                                              148, 0, 0, 0),
                                          child: GridView.count(
                                            crossAxisCount: 2,
                                            children: List.generate(
                                              femaleImagePaths.length,
                                              (index) {
                                                return InkWell(
                                                  onTap: () async {
                                                    Navigator.of(context).pop();
                                                    setState(
                                                      () =>
                                                          changingAvatar = true,
                                                    );
                                                    await changeAvatar(
                                                        false, index);
                                                    setState(() {
                                                      changingAvatar = false;
                                                      didChangeAvatarURL = true;
                                                      currentUser.avatarURL =
                                                          _auth.currentUser!
                                                              .photoURL!;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 10.0),
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.white,
                                                      backgroundImage:
                                                          AssetImage(
                                                        femaleImagePaths[index],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: changingAvatar
                      ? Container(
                          width: 20.0,
                          height: 20.0,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : CircleAvatar(
                          radius: 14.0,
                          backgroundColor:
                              const Color.fromARGB(0, 255, 255, 255),
                          backgroundImage:
                              NetworkImage(_auth.currentUser!.photoURL!),
                        ),
                ),
                StreamBuilder(
                  stream: _firestore.collection('chatdata').snapshots(),
                  builder: (context,
                      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                          snapshot) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => UserChatsPage(
                              publicKey: widget.publicKey,
                              privateKey: widget.privateKey,
                              chatSnapshot: snapshot,
                              confessions: confession_snapshot!.docs,
                              currentIndex: widget.currentIndex,
                              didChangeAvatarURL: didChangeAvatarURL,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.chat,
                          color: Color.fromARGB(255, 249, 249, 249),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
        body: changingAvatar
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  Container(
                      height: 45.0,
                      padding: const EdgeInsets.only(bottom: 0.0, top: 5.0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(255, 20, 175, 247),
                              Color.fromARGB(255, 26, 123, 203)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight),
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
                                  setState(() => indicator = 'MyConfessions');
                                  _pageController.animateToPage(0,
                                      duration:
                                          const Duration(milliseconds: 150),
                                      curve: Curves.linear);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0.0, vertical: 7.0),
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  child: Text(
                                    'My Confessions',
                                    style: GoogleFonts.secularOne(
                                      textStyle: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            Color.fromARGB(255, 249, 249, 249),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() => indicator = 'Others');
                                  _pageController.animateToPage(1,
                                      duration:
                                          const Duration(milliseconds: 150),
                                      curve: Curves.linear);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0.0, vertical: 7.0),
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  child: Text(
                                    'Recieved',
                                    style: GoogleFonts.secularOne(
                                      textStyle: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            Color.fromARGB(255, 249, 249, 249),
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
                            left: indicator == 'MyConfessions'
                                ? 0.0
                                : MediaQuery.of(context).size.width * 0.5,
                            child: Container(
                              height: 40.0,
                              width: MediaQuery.of(context).size.width * 0.5,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          )
                        ],
                      )),
                  Flexible(
                    child: confession_snapshot == null
                        ? const Center(
                            child:
                                Text('Please check your internet connection.'),
                          )
                        : PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              if (index == 0) {
                                setState(
                                  () => indicator = 'MyConfessions',
                                );
                              } else {
                                setState(
                                  () => indicator = 'Others',
                                );
                              }
                            },
                            children: [
                              Builder(
                                builder: (context) {
                                  List userConfessions = [];
                                  for (int i = 0;
                                      i < confession_snapshot!.docs.length;
                                      i++) {
                                    String? confessionSharedKey;
                                    en.Encrypter? encrypter;
                                    final en.Encrypter decrypter = en.Encrypter(
                                        en.RSA(privateKey: widget.privateKey));
                                    for (int j = 0;
                                        j <
                                            confession_snapshot!
                                                .docs[i]['encryptedSharedKeys']
                                                .length;
                                        j++) {
                                      try {
                                        confessionSharedKey = decrypter.decrypt(
                                            en.Encrypted.fromBase64(
                                                confession_snapshot!
                                                            .docs[i] //come-here
                                                        ['encryptedSharedKeys']
                                                    [j]));
                                        encrypter = en.Encrypter(en.AES(
                                            en.Key.fromBase64(
                                                confessionSharedKey)));
                                      } catch (err) {}
                                    }
                                    if (confessionSharedKey != null &&
                                        encrypter != null &&
                                        confession_snapshot!.docs[i]
                                                ['user_uid'] ==
                                            encrypter
                                                .encrypt(_auth.currentUser!.uid,
                                                    iv: en.IV
                                                        .fromBase64('campus12'))
                                                .base64) {
                                      userConfessions
                                          .add(confession_snapshot!.docs[i]);
                                    }
                                  }
                                  if (userConfessions.isEmpty) {
                                    return const Center(
                                      child: Text(
                                          "You haven't confessed anything yet"),
                                    );
                                  } else {
                                    return ListView.builder(
                                      itemCount: userConfessions.length,
                                      itemBuilder: (context, index) {
                                        return ConfessionCardII(
                                          publicKey: widget.publicKey,
                                          privateKey: widget.privateKey,
                                          enablePageView: false,
                                          confessions:
                                              confession_snapshot!.docs,
                                          currentIndex: index,
                                          specificConfessions: userConfessions,
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                              Builder(
                                builder: (context) {
                                  List confessionsForMe = [];
                                  for (int i = 0;
                                      i < confession_snapshot!.docs.length;
                                      i++) {
                                    String? confessionSharedKey;
                                    en.Encrypter? encrypter;
                                    final en.Encrypter decrypter = en.Encrypter(
                                        en.RSA(privateKey: widget.privateKey));
                                    for (int j = 0;
                                        j <
                                            confession_snapshot!
                                                .docs[i]['encryptedSharedKeys']
                                                .length;
                                        j++) {
                                      try {
                                        confessionSharedKey = decrypter.decrypt(
                                            en.Encrypted.fromBase64(
                                                confession_snapshot!.docs[i]
                                                        ['encryptedSharedKeys']
                                                    [j]));
                                        encrypter = en.Encrypter(en.AES(
                                            en.Key.fromBase64(
                                                confessionSharedKey)));
                                      } catch (err) {}
                                    }
                                    if (confessionSharedKey != null &&
                                        encrypter != null &&
                                        confession_snapshot!.docs[i]
                                                ['specificIndividuals']
                                            .contains(encrypter
                                                .encrypt(
                                                    _auth.currentUser!.email!,
                                                    iv: en.IV
                                                        .fromBase64('campus12'))
                                                .base64)) {
                                      confessionsForMe
                                          .add(confession_snapshot!.docs[i]);
                                    }
                                  }
                                  if (confessionsForMe.isEmpty) {
                                    return const Center(
                                      child:
                                          Text("No one confessed to you yet"),
                                    );
                                  } else {
                                    return ListView.builder(
                                      itemCount: confessionsForMe.length,
                                      itemBuilder: (context, index) {
                                        return ConfessionCardII(
                                          publicKey: widget.publicKey,
                                          privateKey: widget.privateKey,
                                          enablePageView: false,
                                          confessions:
                                              confession_snapshot!.docs,
                                          currentIndex: index,
                                          specificConfessions: confessionsForMe,
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
