import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled2/auth_methods.dart';
import 'package:untitled2/confession_home_page.dart';
import 'package:untitled2/email_verify.dart';
import 'package:untitled2/login_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:untitled2/mail_servicesII.dart';
import 'package:untitled2/storage_methods.dart';
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class SignUpPageII extends StatefulWidget {
  SignUpPageII({super.key});

  @override
  State<SignUpPageII> createState() => _SignUpPageIIState();
}

class _SignUpPageIIState extends State<SignUpPageII> {
  String? email;
  String? password;
  String? rePassword;

  bool isPasswordVisible = false;
  bool isRePasswordVisible = false;

  bool isLoading = false;

  Uint8List? avatarImageData;

  final _formKey = GlobalKey<FormState>();

  final PageController _pageController = PageController();

  final AuthMethods _authMethods = AuthMethods();
  final StorageMethods _storageMethods = StorageMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  FlutterSecureStorage? storage;

  @override
  void initState() {
    super.initState();
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  pt.SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pt.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.bottomCenter,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height < 630.0
                    ? MediaQuery.of(context).size.height * 0.7 / 5
                    : MediaQuery.of(context).size.height * 1.1 / 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.lightBlue, Color.fromARGB(255, 2, 98, 177)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15.0),
                    bottomRight: Radius.circular(15.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey, spreadRadius: 1.0, blurRadius: 5.0)
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 0.0, bottom: 10.0),
                  child: Text(
                    'Confessions',
                    style: GoogleFonts.secularOne(
                      textStyle:
                          const TextStyle(fontSize: 35.0, color: Colors.white),
                    ),
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height < 630.0
                    ? MediaQuery.of(context).size.height * 4.07 / 5
                    : MediaQuery.of(context).size.height * 3.6 / 5,
                padding: const EdgeInsets.symmetric(horizontal: 30.0).copyWith(
                    bottom: MediaQuery.of(context).size.height < 630.0
                        ? 5.0
                        : 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(flex: 1, child: Container()),
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height < 630.0
                                ? 0.0
                                : MediaQuery.of(context).size.height < 710.0
                                    ? 0.0
                                    : 0.0,
                            top: MediaQuery.of(context).size.height < 710.0
                                ? 5.0
                                : 0.0),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 28.0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: isLoading ? Colors.grey : Colors.black,
                                width: 1.0),
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.height < 630.0
                                    ? 46.0
                                    : 56.0),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (isLoading) {
                              } else {
                                if (avatarImageData != null) {
                                  setState(
                                    () => avatarImageData = null,
                                  );
                                } else {
                                  Fluttertoast.showToast(
                                      toastLength: Toast.LENGTH_LONG,
                                      textColor: Colors.white,
                                      backgroundColor:
                                          const Color.fromARGB(211, 0, 0, 0),
                                      msg:
                                          "Select your avatar now, and remember, you can change it anytime you wish in the future.");
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Dialog(
                                        child: PageView(
                                          controller: _pageController,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10.0,
                                                      horizontal: 10.0),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Text(
                                                        'Select an avatar',
                                                        style: TextStyle(
                                                            fontSize: 18.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                      Flexible(
                                                          child: Container()),
                                                      InkWell(
                                                        onTap: () {
                                                          _pageController.animateToPage(
                                                              1,
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          150),
                                                              curve: Curves
                                                                  .linear);
                                                        },
                                                        child: const Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Female',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      13.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .arrow_forward,
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
                                                      thumbColor:
                                                          const Color.fromARGB(
                                                              148, 0, 0, 0),
                                                      child: GridView.count(
                                                        crossAxisCount: 2,
                                                        children: List.generate(
                                                          maleImagePaths.length,
                                                          (index) {
                                                            return InkWell(
                                                              onTap: () async {
                                                                ByteData bytes =
                                                                    await rootBundle.load(
                                                                        maleImagePaths[
                                                                            index]);
                                                                Uint8List
                                                                    byteList =
                                                                    bytes.buffer
                                                                        .asUint8List();
                                                                setState(() {
                                                                  avatarImageData =
                                                                      byteList;
                                                                });
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        10.0,
                                                                    vertical:
                                                                        10.0),
                                                                child:
                                                                    CircleAvatar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
                                                                  backgroundImage:
                                                                      AssetImage(
                                                                    maleImagePaths[
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
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10.0,
                                                      horizontal: 10.0),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          _pageController.animateToPage(
                                                              0,
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          150),
                                                              curve: Curves
                                                                  .linear);
                                                        },
                                                        child: const Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.arrow_back,
                                                              size: 15.0,
                                                            ),
                                                            Text(
                                                              'Male',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      13.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Flexible(
                                                          child: Container()),
                                                    ],
                                                  ),
                                                  Expanded(
                                                    child: RawScrollbar(
                                                      thickness: 2.0,
                                                      thumbColor:
                                                          const Color.fromARGB(
                                                              148, 0, 0, 0),
                                                      child: GridView.count(
                                                        crossAxisCount: 2,
                                                        children: List.generate(
                                                          femaleImagePaths
                                                              .length,
                                                          (index) {
                                                            return InkWell(
                                                              onTap: () async {
                                                                ByteData bytes =
                                                                    await rootBundle.load(
                                                                        femaleImagePaths[
                                                                            index]);
                                                                Uint8List
                                                                    byteList =
                                                                    bytes.buffer
                                                                        .asUint8List();
                                                                setState(() {
                                                                  avatarImageData =
                                                                      byteList;
                                                                });
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        10.0,
                                                                    vertical:
                                                                        10.0),
                                                                child:
                                                                    CircleAvatar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
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
                                      );
                                    },
                                  );
                                }
                              }
                            },
                            child: CircleAvatar(
                                radius:
                                    MediaQuery.of(context).size.height < 630.0
                                        ? 45.0
                                        : 55.0,
                                backgroundColor: avatarImageData != null
                                    ? Colors.black
                                    : const Color.fromARGB(0, 255, 255, 255),
                                backgroundImage: avatarImageData == null
                                    ? null
                                    : MemoryImage(avatarImageData!),
                                child: avatarImageData == null
                                    ? const Icon(
                                        Icons.person_add,
                                        size: 40.0,
                                        color:
                                            Color.fromARGB(255, 184, 184, 184),
                                      )
                                    : Container()),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: TextFormField(
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.height < 630.0
                                        ? 2.0
                                        : 15.0,
                                horizontal: 20.0),
                            labelText: 'Email',
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(width: 1.0),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Color.fromARGB(255, 3, 145, 211),
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Colors.red,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Colors.red,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            disabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1.0, color: Colors.grey),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == '') {
                              Fluttertoast.showToast(
                                textColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(211, 0, 0, 0),
                                msg: 'Email field must not be empty',
                              );
                              return 'Empty email field';
                            } else if (!value!.contains('@iitk.ac.in')) {
                              Fluttertoast.showToast(
                                msg: 'Invalid email',
                                textColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(211, 0, 0, 0),
                              );
                              return 'only @iitk.ac.in';
                            } else {
                              return null;
                            }
                          },
                          onSaved: (newValue) =>
                              setState(() => email = newValue),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: TextFormField(
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                  () => isPasswordVisible = !isPasswordVisible),
                              // onLongPressDown: (LongPressDownDetails _) =>
                              //     setState(() => isPasswordVisible = true),
                              // onLongPressUp: () =>
                              //     setState(() => isPasswordVisible = false),
                              child: isPasswordVisible
                                  ? const Icon(Icons.visibility_off)
                                  : const Icon(Icons.visibility),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.height < 630.0
                                        ? 2.0
                                        : 15.0,
                                horizontal: 20.0),
                            labelText: 'Password',
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(width: 1.0),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Color.fromARGB(255, 3, 145, 211),
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Colors.red,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Colors.red,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            disabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1.0, color: Colors.grey),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == '') {
                              Fluttertoast.showToast(
                                msg: 'Password field must not be empty',
                                textColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(211, 0, 0, 0),
                              );
                              return 'Empty password field';
                            } else if (value!.length < 8) {
                              Fluttertoast.showToast(
                                msg: 'Password must be atleast 8 characters',
                                textColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(211, 0, 0, 0),
                              );
                              return 'atleast 8 characters';
                            } else {
                              return null;
                            }
                          },
                          onSaved: (newValue) =>
                              setState(() => password = newValue),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: TextFormField(
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          obscureText: !isRePasswordVisible,
                          decoration: InputDecoration(
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() =>
                                  isRePasswordVisible = !isRePasswordVisible),
                              // onLongPressDown: (LongPressDownDetails _) =>
                              //     setState(() => isRePasswordVisible = true),
                              // onLongPressUp: () =>
                              //     setState(() => isRePasswordVisible = false),
                              child: isRePasswordVisible
                                  ? const Icon(Icons.visibility_off)
                                  : const Icon(Icons.visibility),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.height < 630.0
                                        ? 2.0
                                        : 15.0,
                                horizontal: 20.0),
                            labelText: 'Re-enter password',
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(width: 1.0),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Color.fromARGB(255, 3, 145, 211),
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Colors.red,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Colors.red,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            disabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1.0, color: Colors.grey),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == '') {
                              Fluttertoast.showToast(
                                msg: 'Password field must not be empty',
                                textColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(211, 0, 0, 0),
                              );
                              return 'Empty password field';
                            } else if (value!.length < 8) {
                              Fluttertoast.showToast(
                                msg: 'Password must be atleast 8 characters',
                                textColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(211, 0, 0, 0),
                              );
                              return 'atleast 8 characters';
                            } else {
                              return null;
                            }
                          },
                          onSaved: (newValue) =>
                              setState(() => rePassword = newValue),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height < 630.0
                                ? 2.0
                                : MediaQuery.of(context).size.height < 710.0
                                    ? 10.0
                                    : 25.0,
                            bottom: 0.0),
                        child: InkWell(
                          onTap: () async {
                            final isValid = _formKey.currentState!.validate();
                            if (isValid) {
                              _formKey.currentState!.save();
                              if (avatarImageData == null) {
                                Fluttertoast.showToast(
                                    textColor: Colors.white,
                                    backgroundColor:
                                        const Color.fromARGB(211, 0, 0, 0),
                                    msg: 'Please select your avatar');
                              } else if (password != rePassword) {
                                Fluttertoast.showToast(
                                    textColor: Colors.white,
                                    backgroundColor:
                                        const Color.fromARGB(211, 0, 0, 0),
                                    msg: 'Passwords are not matching');
                              } else {
                                setState(
                                  () => isLoading = true,
                                );
                                Fluttertoast.showToast(
                                  msg:
                                      'Please hold on, this could take a little while.',
                                  textColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(211, 0, 0, 0),
                                );
                                String authRes = await _authMethods.SignUpUser(
                                    email!, password!, avatarImageData);
                                if (authRes == 'successfully signed up!') {
                                  String storageRes = await _storageMethods
                                      .uploadImageToStorage(
                                          'Avatars',
                                          _auth.currentUser!.uid,
                                          avatarImageData!);
                                  if (storageRes == 'Some error occurred') {
                                    Fluttertoast.showToast(
                                      msg:
                                          'Failed to upload your avatar. Sorry for the inconvenience and please try again.',
                                      textColor: Colors.white,
                                      backgroundColor:
                                          const Color.fromARGB(211, 0, 0, 0),
                                    );
                                    try {
                                      await _auth.currentUser?.delete();
                                    } catch (err) {
                                      Fluttertoast.showToast(
                                        msg:
                                            'If you encounter any difficulty in signing up again, kindly send an email to teamconfessionsiitk@gmail.com for further assistance.',
                                        textColor: Colors.white,
                                        backgroundColor:
                                            const Color.fromARGB(211, 0, 0, 0),
                                      );
                                    }
                                  } else {
                                    _auth.currentUser!
                                        .updatePhotoURL(storageRes);
                                    _auth.currentUser!.updateEmail(email!);
                                    try {
                                      final keyGen = RSAKeyGenerator()
                                        ..init(pt.ParametersWithRandom(
                                            RSAKeyGeneratorParameters(
                                                BigInt.parse('65537'),
                                                1024,
                                                12),
                                            _getSecureRandom()));
                                      final keypair = keyGen.generateKeyPair();
                                      final privatekey = keypair.privateKey
                                          as pt.RSAPrivateKey;
                                      final publickey =
                                          keypair.publicKey as pt.RSAPublicKey;
                                      final String privateKey_modulus =
                                          privatekey.modulus!.toString();
                                      final String privateKey_exponent =
                                          privatekey.exponent!.toString();
                                      final String privateKey_p =
                                          privatekey.p!.toString();
                                      final String privateKey_q =
                                          privatekey.q!.toString();
                                      final String publicKey_modulus =
                                          publickey.modulus!.toString();
                                      final String publicKey_exponent =
                                          publickey.exponent!.toString();
                                      await storage?.write(
                                          key: 'Private Key modulus',
                                          value: privateKey_modulus);
                                      await storage?.write(
                                          key: 'Private Key exponent',
                                          value: privateKey_exponent);
                                      await storage?.write(
                                          key: 'Private Key p',
                                          value: privateKey_p);
                                      await storage?.write(
                                          key: 'Private Key q',
                                          value: privateKey_q);
                                      await storage?.write(
                                          key: 'Public Key modulus',
                                          value: publicKey_modulus);
                                      await storage?.write(
                                          key: 'Public Key exponent',
                                          value: publicKey_exponent);
                                      await _firestore
                                          .collection('users')
                                          .doc(_auth.currentUser!.uid)
                                          .update({
                                        'public_key_exponent':
                                            publicKey_exponent,
                                        'public_key_modulus': publicKey_modulus
                                      });
                                      email !=
                                              'googleConfessionAppVerification369@iitk.ac.in'
                                          ? await _auth.currentUser!
                                              .sendEmailVerification()
                                          : null;
                                      email ==
                                              'googleConfessionAppVerification369@iitk.ac.in'
                                          ? _auth.currentUser!.emailVerified ==
                                              true
                                          : null;
                                      email !=
                                              'googleConfessionAppVerification369@iitk.ac.in'
                                          ? Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Emailverify()))
                                          : Navigator.of(context)
                                              .pushReplacement(MaterialPageRoute(
                                                  builder: (context) =>
                                                      ConfessionHomePage()));
                                    } catch (err) {
                                      await _auth.currentUser?.delete();
                                      Fluttertoast.showToast(
                                        msg:
                                            'Failed to generate your crypto keys. Please try again',
                                        textColor: Colors.white,
                                        backgroundColor:
                                            const Color.fromARGB(211, 0, 0, 0),
                                      );
                                    }
                                  }
                                } else if (authRes.toLowerCase().contains(
                                    'email address is already in use')) {
                                  Fluttertoast.showToast(
                                    msg: 'The email address is already in use',
                                    textColor: Colors.white,
                                    backgroundColor:
                                        const Color.fromARGB(211, 0, 0, 0),
                                  );
                                } else if (authRes
                                    .toLowerCase()
                                    .contains('network error')) {
                                  Fluttertoast.showToast(
                                    msg:
                                        'Please check your internet connection',
                                    textColor: Colors.white,
                                    backgroundColor:
                                        const Color.fromARGB(211, 0, 0, 0),
                                  );
                                } else {
                                  Fluttertoast.showToast(
                                    msg:
                                        'Some unidentified error occurred. Please try again.',
                                    textColor: Colors.white,
                                    backgroundColor:
                                        const Color.fromARGB(211, 0, 0, 0),
                                  );
                                }
                                setState(
                                  () => isLoading = false,
                                );
                              }
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 50.0),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.lightBlue,
                                  Color.fromARGB(255, 20, 117, 197)
                                ],
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey,
                                  spreadRadius: 0.1,
                                  blurRadius: 0.5,
                                ),
                              ],
                            ),
                            child: isLoading
                                ? Container(
                                    width: 25.0,
                                    height: 25.0,
                                    child: const CircularProgressIndicator(
                                      backgroundColor: Colors.white,
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : const Text(
                                    'Sign up',
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                      Flexible(flex: 2, child: Container()),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(
                                fontSize: 15.0,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: InkWell(
                                onTap: () =>
                                    Navigator.of(context).pushReplacement(
                                  CupertinoPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) => LoginPage(),
                                  ),
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height < 630.0
                    ? MediaQuery.of(context).size.height * 0.23 / 5
                    : MediaQuery.of(context).size.height * 0.3 / 5,
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.lightBlue, Color.fromARGB(255, 2, 98, 177)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    topRight: Radius.circular(15.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      spreadRadius: 1.0,
                      blurRadius: 5.0,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
