import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:untitled2/CryptoKeyInputPage.dart';
import 'package:untitled2/auth_methods.dart';
import 'package:untitled2/confession_home_page.dart';
import 'package:untitled2/email_verify.dart';
import 'package:untitled2/signup_pageII.dart';
import 'package:pointycastle/pointycastle.dart' as pt;

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  String? email;
  String? password;
  bool isPasswordVisible = false;

  bool isLoading = false;

  FlutterSecureStorage? secureStorage;

  final AuthMethods _authMethods = AuthMethods();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    secureStorage = FlutterSecureStorage(aOptions: _getAndroidOptions());
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
                height: MediaQuery.of(context).size.height * 1.25 / 5,
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
                height: MediaQuery.of(context).size.height * 3.3 / 5,
                padding: const EdgeInsets.symmetric(horizontal: 30.0)
                    .copyWith(bottom: 30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(flex: 1, child: Container()),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 30.0, top: 20.0),
                        child: Text(
                          'Login',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 28.0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: TextFormField(
                          onChanged: (value) {
                            setState(
                              () => email = value,
                            );
                          },
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 20.0),
                            labelText: 'Email',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(width: 1.0),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Color.fromARGB(255, 3, 145, 211),
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Colors.red,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Colors.red,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
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
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: TextFormField(
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                  () => isPasswordVisible = !isPasswordVisible),
                              child: isPasswordVisible
                                  ? const Icon(Icons.visibility_off)
                                  : const Icon(Icons.visibility),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 20.0),
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
                        padding: const EdgeInsets.only(top: 40.0, bottom: 0.0),
                        child: InkWell(
                          onTap: () async {
                            final isValid = _formKey.currentState!.validate();
                            if (isValid) {
                              _formKey.currentState!.save();
                              setState(
                                () => isLoading = true,
                              );
                              try {
                                QuerySnapshot<Map<String, dynamic>> userSnap =
                                    await _firestore
                                        .collection('users')
                                        .where('email', isEqualTo: email!)
                                        .get();
                                if (userSnap.docs.isNotEmpty &&
                                    (await secureStorage!.read(
                                                key: 'Public Key modulus') ==
                                            null ||
                                        await secureStorage!.read(
                                                key: 'Public Key exponent') ==
                                            null ||
                                        await secureStorage!.read(
                                                key: 'Private Key modulus') ==
                                            null ||
                                        await secureStorage!.read(
                                                key: 'Private Key exponent') ==
                                            null)) {
                                  Fluttertoast.showToast(
                                    msg:
                                        'Looks like you have lost your encryption keys. We are generating new ones...',
                                    textColor: Colors.white,
                                    backgroundColor:
                                        const Color.fromARGB(211, 0, 0, 0),
                                  );
                                  final keyGen = RSAKeyGenerator()
                                    ..init(pt.ParametersWithRandom(
                                        RSAKeyGeneratorParameters(
                                            BigInt.parse('65537'), 1024, 12),
                                        _getSecureRandom()));
                                  final keypair = keyGen.generateKeyPair();
                                  final privatekey =
                                      keypair.privateKey as pt.RSAPrivateKey;
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
                                  await secureStorage!.write(
                                      key: 'Private Key modulus',
                                      value: privateKey_modulus);
                                  await secureStorage!.write(
                                      key: 'Private Key exponent',
                                      value: privateKey_exponent);
                                  await secureStorage!.write(
                                      key: 'Private Key p',
                                      value: privateKey_p);
                                  await secureStorage!.write(
                                      key: 'Private Key q',
                                      value: privateKey_q);
                                  await secureStorage!.write(
                                      key: 'Public Key modulus',
                                      value: publicKey_modulus);
                                  await secureStorage!.write(
                                      key: 'Public Key exponent',
                                      value: publicKey_exponent);
                                  await _firestore
                                      .collection('users')
                                      .doc(userSnap.docs[0]['uid'])
                                      .update({
                                    'public_key_exponent': publicKey_exponent,
                                    'public_key_modulus': publicKey_modulus
                                  });
                                } else if (userSnap.docs.isNotEmpty &&
                                    (await secureStorage!.read(
                                                key: 'Public Key modulus') !=
                                            userSnap.docs[0]
                                                ['public_key_modulus'] ||
                                        await secureStorage!.read(
                                                key: 'Public Key exponent') !=
                                            userSnap.docs[0]['public_key_exponent'])) {
                                  Fluttertoast.showToast(
                                    msg:
                                        'Looks like you have lost your encryption keys. We are generating new ones...',
                                    textColor: Colors.white,
                                    backgroundColor:
                                        const Color.fromARGB(211, 0, 0, 0),
                                  );
                                  final keyGen = RSAKeyGenerator()
                                    ..init(pt.ParametersWithRandom(
                                        RSAKeyGeneratorParameters(
                                            BigInt.parse('65537'), 1024, 12),
                                        _getSecureRandom()));
                                  final keypair = keyGen.generateKeyPair();
                                  final privatekey =
                                      keypair.privateKey as pt.RSAPrivateKey;
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
                                  await secureStorage?.write(
                                      key: 'Private Key modulus',
                                      value: privateKey_modulus);
                                  await secureStorage?.write(
                                      key: 'Private Key exponent',
                                      value: privateKey_exponent);
                                  await secureStorage?.write(
                                      key: 'Private Key p',
                                      value: privateKey_p);
                                  await secureStorage?.write(
                                      key: 'Private Key q',
                                      value: privateKey_q);
                                  await secureStorage?.write(
                                      key: 'Public Key modulus',
                                      value: publicKey_modulus);
                                  await secureStorage?.write(
                                      key: 'Public Key exponent',
                                      value: publicKey_exponent);
                                  await _firestore
                                      .collection('users')
                                      .doc(userSnap.docs[0]['uid'])
                                      .update({
                                    'public_key_exponent': publicKey_exponent,
                                    'public_key_modulus': publicKey_modulus
                                  });
                                }
                                String res = await _authMethods.LoginUser(
                                    email!, password!);
                                if (res == 'successfully logged in.') {
                                  if (email !=
                                          'googleConfessionAppVerification369@iitk.ac.in' &&
                                      !_auth.currentUser!.emailVerified) {
                                    _auth.currentUser!.sendEmailVerification();
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const Emailverify()));
                                  } else {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ConfessionHomePage(),
                                      ),
                                    );
                                  }
                                } else {
                                  if (res
                                      .toLowerCase()
                                      .contains('no user record')) {
                                    Fluttertoast.showToast(
                                      msg:
                                          'Account not found. Please check your credentials or create a new account.',
                                      textColor: Colors.white,
                                      backgroundColor:
                                          const Color.fromARGB(211, 0, 0, 0),
                                    );
                                  } else if (res
                                      .toLowerCase()
                                      .contains('password is invalid')) {
                                    Fluttertoast.showToast(
                                      msg:
                                          'Invalid Password. Please double-check your password and try again.',
                                      textColor: Colors.white,
                                      backgroundColor:
                                          const Color.fromARGB(211, 0, 0, 0),
                                    );
                                  } else if (res
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
                                }
                              } catch (err) {
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
                          },
                          child: Container(
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
                                    'Login',
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
                        padding: const EdgeInsets.only(bottom: 7.0),
                        child: InkWell(
                          onTap: () async {
                            if (email != null) {
                              try {
                                await _auth.sendPasswordResetEmail(
                                    email: email!);
                                Fluttertoast.showToast(
                                  toastLength: Toast.LENGTH_LONG,
                                  msg:
                                      "We have sent you a reset email to your mailID. Please check in the spam section too.",
                                  textColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(211, 0, 0, 0),
                                );
                              } catch (err) {
                                Fluttertoast.showToast(
                                  toastLength: Toast.LENGTH_LONG,
                                  msg: "Some error occurred. Please try again.",
                                  textColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(211, 0, 0, 0),
                                );
                              }
                            } else {
                              Fluttertoast.showToast(
                                toastLength: Toast.LENGTH_LONG,
                                msg: "Email must not be empty",
                                textColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(211, 0, 0, 0),
                              );
                            }
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(
                                fontSize: 15.0,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: InkWell(
                                onTap: () async {
                                  Navigator.of(context).pushReplacement(
                                    CupertinoPageRoute(
                                      fullscreenDialog: true,
                                      builder: (context) => SignUpPageII(),
                                    ),
                                  );
                                  await Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () => Fluttertoast.showToast(
                                      toastLength: Toast.LENGTH_LONG,
                                      msg:
                                          "We use Firebase's secure systems for account creation. Your password is encrypted, and even we can't access it.",
                                      textColor: Colors.white,
                                      backgroundColor:
                                          const Color.fromARGB(211, 0, 0, 0),
                                    ),
                                  );
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () => Fluttertoast.showToast(
                                      toastLength: Toast.LENGTH_LONG,
                                      msg:
                                          "We generate account-specific encryption keys at registration. These keys are secure and only you know them.",
                                      textColor: Colors.white,
                                      backgroundColor:
                                          const Color.fromARGB(211, 0, 0, 0),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'SignUp',
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
                height: MediaQuery.of(context).size.height * 0.45 / 5,
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
