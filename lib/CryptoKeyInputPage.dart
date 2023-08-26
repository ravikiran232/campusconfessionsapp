import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:untitled2/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CryptoKeysInputPage extends StatefulWidget {
  bool differenceAccount;
  QuerySnapshot<Map<String, dynamic>> userSnapshot;
  CryptoKeysInputPage(
      {super.key, required this.userSnapshot, this.differenceAccount = false});

  @override
  State<CryptoKeysInputPage> createState() => _CryptoKeysInputPageState();
}

class _CryptoKeysInputPageState extends State<CryptoKeysInputPage> {
  String? publicKeyModulus;
  String? publicKeyExponent;
  String? privateKeyModulus;
  String? privateKeyExponent;
  String? privateKeyP;
  String? privateKeyQ;

  bool isLoading = false;

  FlutterSecureStorage? storage;

  @override
  void initState() {
    super.initState();
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
  }

  final GlobalKey<FormState> _formKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  !widget.differenceAccount
                      ? const Text(
                          'Oops! It appears your encryption keys are not found in your storage. These keys are crucial to access your data. Please enter the following details to log in. Remember, these encryption keys were emailed to you when you initially set up your account. Important: Once your details are submitted, they cannot be modified. Please ensure to enter your information carefully!')
                      : const Text(
                          "It seems like you're attempting to log in using a different account. The encryption keys you've entered don't match the ones from your previously logged-in account. Please ensure to input the correct encryption keys for your current account to access your data. It is recommended to use only 1 acocunt per device. Incase, any unsolvable error occurs, please mail to teamconfessionsiitk@gmail.com."),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                                hintText: 'Enter your public key modulus'),
                            validator: (value) {
                              if (value == null || value == '') {
                                Fluttertoast.showToast(
                                  textColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(211, 0, 0, 0),
                                  msg: 'Invalid public key modulus',
                                );
                                return 'Invalid public key modulus';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (newValue) =>
                                setState(() => publicKeyModulus = newValue),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                                hintText: 'Enter your public key exponent'),
                            validator: (value) {
                              if (value == null || value == '') {
                                Fluttertoast.showToast(
                                  textColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(211, 0, 0, 0),
                                  msg: 'Invalid public key exponent',
                                );
                                return 'Invalid public key exponent';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (newValue) =>
                                setState(() => publicKeyExponent = newValue),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                                hintText: 'Enter your private key modulus'),
                            validator: (value) {
                              if (value == null || value == '') {
                                Fluttertoast.showToast(
                                  textColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(211, 0, 0, 0),
                                  msg: 'Invalid private key modulus',
                                );
                                return 'Invalid private key modulus';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (newValue) =>
                                setState(() => privateKeyModulus = newValue),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                                hintText: 'Enter your private key exponent'),
                            validator: (value) {
                              if (value == null || value == '') {
                                Fluttertoast.showToast(
                                  textColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(211, 0, 0, 0),
                                  msg: 'Invalid private key exponent',
                                );
                                return 'Invalid private key exponent';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (newValue) =>
                                setState(() => privateKeyExponent = newValue),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                                hintText: 'Enter your private key p value'),
                            validator: (value) {
                              if (value == null || value == '') {
                                Fluttertoast.showToast(
                                  textColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(211, 0, 0, 0),
                                  msg: 'Invalid private key p value',
                                );
                                return 'Invalid private key p value';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (newValue) =>
                                setState(() => privateKeyP = newValue),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                                hintText: 'Enter your private key q value'),
                            validator: (value) {
                              if (value == null || value == '') {
                                Fluttertoast.showToast(
                                  textColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(211, 0, 0, 0),
                                  msg: 'Invalid private key q value',
                                );
                                return 'Invalid private key q value';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (newValue) =>
                                setState(() => privateKeyQ = newValue),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30.0),
                          child: isLoading
                              ? const Text(
                                  'Loading...',
                                  style: TextStyle(color: Colors.blue),
                                )
                              : TextButton(
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.blue)),
                                  onPressed: () async {
                                    final isValid =
                                        _formKey.currentState!.validate();
                                    if (isValid) {
                                      _formKey.currentState!.save();
                                      if (publicKeyModulus !=
                                          widget.userSnapshot.docs[0]
                                              ['public_key_modulus']) {
                                        Fluttertoast.showToast(
                                          textColor: Colors.white,
                                          backgroundColor: const Color.fromARGB(
                                              211, 0, 0, 0),
                                          msg:
                                              'Entered public key modulus is not yours',
                                        );
                                      } else if (publicKeyExponent !=
                                          widget.userSnapshot.docs[0]
                                              ['public_key_exponent']) {
                                        Fluttertoast.showToast(
                                          textColor: Colors.white,
                                          backgroundColor: const Color.fromARGB(
                                              211, 0, 0, 0),
                                          msg:
                                              'Entered public key exponent is not yours',
                                        );
                                      } else {
                                        try {
                                          setState(
                                            () => isLoading = true,
                                          );
                                          await storage!.write(
                                              key: 'Private Key modulus',
                                              value: privateKeyModulus);
                                          await storage!.write(
                                              key: 'Private Key exponent',
                                              value: privateKeyExponent);
                                          await storage!.write(
                                              key: 'Private Key p',
                                              value: privateKeyP);
                                          await storage!.write(
                                              key: 'Private Key q',
                                              value: privateKeyQ);
                                          await storage!.write(
                                              key: 'Public Key modulus',
                                              value: publicKeyModulus);
                                          await storage!.write(
                                              key: 'Public Key exponent',
                                              value: publicKeyExponent);
                                          setState(
                                            () => isLoading = false,
                                          );
                                          Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      LoginPage()));
                                          Fluttertoast.showToast(
                                            textColor: Colors.white,
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    211, 0, 0, 0),
                                            msg:
                                                'Successfully added encryption keys',
                                          );
                                        } catch (err) {
                                          Fluttertoast.showToast(
                                            textColor: Colors.white,
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    211, 0, 0, 0),
                                            msg:
                                                'Some error occurred. Please try again later.',
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Submit',
                                    style: TextStyle(
                                        color:
                                            Color.fromARGB(255, 234, 39, 25)),
                                  )),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
