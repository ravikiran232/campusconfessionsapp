import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/FrontLoadingPage.dart';
import 'package:untitled2/UserProfile.dart';
import 'package:untitled2/auth_methods.dart';
import 'package:untitled2/confession_home_body.dart';
import 'package:untitled2/login_page.dart';
import 'package:untitled2/rankings_page.dart';
import 'package:untitled2/share_services.dart';
import 'package:untitled2/storage_methods.dart';
import 'package:untitled2/user_provider.dart';
import 'notification_services.dart';
import 'models.dart' as Models;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class ConfessionHomePage extends StatefulWidget {
  ConfessionHomePage({super.key});

  @override
  State<ConfessionHomePage> createState() => _ConfessionHomePageState();
}

class _ConfessionHomePageState extends State<ConfessionHomePage> {
  final AuthMethods _authMethods = AuthMethods();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final NotificationServices notificationServices = NotificationServices();

  bool gettingKeys = true;

  FlutterSecureStorage? secureStorage;
  String publicKey_modulus = '';
  String publicKey_exponent = "";
  String privateKey_p = '';
  String privateKey_q = '';
  String privateKey_exponent = '';
  String privateKey_modulus = '';
  pt.RSAPublicKey? publicKey;
  pt.RSAPrivateKey? privateKey;

  List<dynamic> _admins = [];
  String primaryAdmin = '';

  final PageController _pageController = PageController();

  bool changingAvatar = false;

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

  final StorageMethods _storageMethods = StorageMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  QuerySnapshot<Map<String, dynamic>>? confessionSnapshot;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _confessions = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  QuerySnapshot<Map<String, dynamic>>? lastMonthConfessionSnapshot;

  bool isLoading = false;

  int _dataLimit = 10;

  Future<List<dynamic>> getAdminUIds() async {
    DocumentSnapshot<Map<String, dynamic>> adminDocSnap =
        await _firestore.collection('users').doc('admins').get();
    return [adminDocSnap['admins'], adminDocSnap['primaryAdmin']];
  }

  pt.SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pt.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  @override
  void initState() {
    super.initState();

    addData();
    _getInitialConfessionData();

    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      secureStorage = FlutterSecureStorage(aOptions: _getAndroidOptions());
      publicKey_modulus =
          (await secureStorage!.read(key: 'Public Key modulus'))!;
      publicKey_exponent =
          (await secureStorage!.read(key: 'Public Key exponent'))!;
      privateKey_exponent =
          (await secureStorage!.read(key: 'Private Key exponent'))!;
      privateKey_modulus =
          (await secureStorage!.read(key: 'Private Key modulus'))!;
      privateKey_p = (await secureStorage!.read(key: 'Private Key p'))!;
      privateKey_q = (await secureStorage!.read(key: 'Private Key q'))!;

      List<dynamic> adminRes = await getAdminUIds();

      setState(() {
        publicKey = pt.RSAPublicKey(
            BigInt.parse(publicKey_modulus), BigInt.parse(publicKey_exponent));
        privateKey = pt.RSAPrivateKey(
            BigInt.parse(privateKey_modulus),
            BigInt.parse(privateKey_exponent),
            BigInt.parse(privateKey_p),
            BigInt.parse(privateKey_q));
        gettingKeys = false;
        _admins = adminRes[0];
        primaryAdmin = adminRes[1];
      });

      notificationServices.requestNotificationPermission();
      notificationServices.setupInteractMessage(
          context, publicKey, privateKey, _admins, primaryAdmin);
      notificationServices.firebaseInit(
          context, publicKey, privateKey, _admins, primaryAdmin);
      notificationServices.refreshToken(context);
      ShareServices().initDynamicLink(context, publicKey, privateKey);
      ShareServices().handleDynamicLink(context, publicKey, privateKey);
    });
  }

  void addData() async {
    UserProvider _userProvider = Provider.of(context, listen: false);
    await _userProvider.refreshUser();
  }

  void _getInitialConfessionData() async {
    setState(
      () => isLoading = true,
    );
    DateTime now = DateTime.now();
    DateTime lastMonth = now.subtract(const Duration(days: 14));
    confessionSnapshot = await _firestore
        .collection('confessions')
        .orderBy('datePublished', descending: true)
        .limit(_dataLimit)
        .get();
    lastMonthConfessionSnapshot = await _firestore
        .collection('confessions')
        .where('datePublished', isGreaterThan: lastMonth)
        .get();
    _confessions = confessionSnapshot!.docs;
    if (_confessions.isNotEmpty) {
      if (_confessions.length < _dataLimit) {
        _hasMoreData = false;
      }
      _lastDoc = _confessions[_confessions.length - 1];
    }
    setState(
      () => isLoading = false,
    );
  }

  bool _hasMoreData = true;

  void _getMoreConfessionData() async {
    confessionSnapshot = await _firestore
        .collection('confessions')
        .orderBy('datePublished', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_dataLimit)
        .get();
    if (confessionSnapshot!.docs.length < _dataLimit ||
        confessionSnapshot!.docs.isEmpty) {
      setState(
        () => _hasMoreData = false,
      );
    }
    _confessions.addAll(confessionSnapshot!.docs);
    _lastDoc = _confessions[_confessions.length - 1];
    setState(
      () {},
    );
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

  Future<void> _handleRefresh() async {
    QuerySnapshot<Map<String, dynamic>> newSnapshot = await _firestore
        .collection('confessions')
        .orderBy('datePublished', descending: true)
        .limit(_dataLimit)
        .get();
    setState(() {
      _confessions = newSnapshot.docs;
      _hasMoreData = true;
      _lastDoc = _confessions[_confessions.length - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(239, 254, 254, 254),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0.0,
          titleSpacing: 0.0,
          title: Container(
            height: 57.0,
            padding: const EdgeInsets.only(left: 10.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.lightBlue, Color.fromARGB(255, 26, 123, 203)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
            ),
            child: Row(
              children: [
                Text(
                  'Confessions',
                  style: GoogleFonts.secularOne(
                    textStyle: const TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 249, 249, 249),
                        letterSpacing: 0.5),
                  ),
                ),
                Flexible(child: Container()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: InkWell(
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
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(
                                                        () => changingAvatar =
                                                            true,
                                                      );
                                                      await changeAvatar(
                                                          true, index);
                                                      setState(() {
                                                        changingAvatar = false;
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
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(
                                                        () => changingAvatar =
                                                            true,
                                                      );
                                                      await changeAvatar(
                                                          false, index);
                                                      setState(() {
                                                        changingAvatar = false;
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
                                                          femaleImagePaths[
                                                              index],
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
                ),
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => SimpleDialog(
                      titlePadding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 10.0),
                      title: const Text(
                        "Are you sure?",
                        style: TextStyle(fontSize: 20.0),
                      ),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 5.0),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                      fontSize: 17.0,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                String res = await _authMethods.logOutUser();
                                if (res == 'successfully logged out.') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(),
                                    ),
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 5.0),
                                child: Text(
                                  "Logout",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 241, 64, 51),
                                      fontSize: 17.0,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout,
                    size: 30.0,
                    color: Color.fromARGB(255, 249, 249, 249),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: isLoading || gettingKeys
            // ? const Center(
            //     child: CircularProgressIndicator(
            //       color: Color.fromARGB(255, 4, 151, 219),
            //     ),
            //   )
            ? const FrontLoadingPage()
            : _confessions.isEmpty
                ? ConfessionHomeBody(
                    //key: ValueKey(_confessions[0]),
                    admins: _admins,
                    primaryAdmin: primaryAdmin,
                    publicKey: publicKey,
                    privateKey: privateKey,
                    confessions: _confessions,
                    handleRefresh: _handleRefresh,
                    getMoreConfessionData: _getMoreConfessionData,
                    hasMoreData: _hasMoreData,
                    lastMonthConfessionSnapshot: lastMonthConfessionSnapshot,
                  )
                : ConfessionHomeBody(
                    key: ValueKey(_confessions[0]),
                    admins: _admins,
                    primaryAdmin: primaryAdmin,
                    publicKey: publicKey,
                    privateKey: privateKey,
                    confessions: _confessions,
                    handleRefresh: _handleRefresh,
                    getMoreConfessionData: _getMoreConfessionData,
                    hasMoreData: _hasMoreData,
                    lastMonthConfessionSnapshot: lastMonthConfessionSnapshot,
                  ),
      ),
    );
  }
}
