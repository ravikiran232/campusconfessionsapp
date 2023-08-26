import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:untitled2/auth_methods.dart';
import 'package:untitled2/firestore_methods.dart';
import 'package:untitled2/models.dart' as Models;
import 'package:untitled2/notification_services.dart';
import 'package:untitled2/user_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'FrontLoadingPage.dart';
import 'mail_servicesII.dart';
import 'package:http/http.dart' as http;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class NewConfessionPage extends StatefulWidget {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  List<dynamic> admins;
  int confessionNum;
  NewConfessionPage(
      {super.key,
      required this.admins,
      required this.publicKey,
      required this.privateKey,
      required this.confessionNum});

  @override
  State<NewConfessionPage> createState() => _NewConfessionPageState();
}

class _NewConfessionPageState extends State<NewConfessionPage> {
  bool _enableSpecificIndividuals = false;
  bool _enableAnonymousChat = false;
  bool _enablePoll = false;
  bool _postAsAdmin = false;
  int numPollOptions = 2;
  final FocusNode _speficiIndividualsFocusNode = FocusNode();
  final FocusNode _confessionFocusNode = FocusNode();
  final TextEditingController _specificIndividualsController =
      TextEditingController();
  final TextEditingController _confessionController = TextEditingController();
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];

  final FirestoreMethods _firestoreMethods = FirestoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthMethods _authMethods = AuthMethods();

  bool _postingConfession = false;
  bool _notifyingAdmins = false;

  NotificationServices notificationServices = NotificationServices();

  @override
  void dispose() {
    super.dispose();
    _speficiIndividualsFocusNode.dispose();
    _confessionFocusNode.dispose();
    _confessionController.dispose();
    _specificIndividualsController.dispose();
    for (int i = 0; i < 4; i++) {
      _pollOptionControllers[i].dispose();
    }
  }

  Future<Map<String, pt.RSAPublicKey>> fetchPublicKeys(
      List<dynamic> mailList) async {
    Map<String, pt.RSAPublicKey> output = {};
    QuerySnapshot<Map<String, dynamic>> specificIndividualsSnap =
        await _firestore
            .collection('users')
            .where('email', whereIn: mailList)
            .get();
    for (int i = 0; i < specificIndividualsSnap.docs.length; i++) {
      String public_modulus =
          specificIndividualsSnap.docs[i]['public_key_modulus'];
      String public_exponent =
          specificIndividualsSnap.docs[i]['public_key_exponent'];
      output[specificIndividualsSnap.docs[i]['email']] = pt.RSAPublicKey(
          BigInt.parse(public_modulus), BigInt.parse(public_exponent));
    }
    return output;
  }

  String verifyEmailFormat(List<dynamic> mailList) {
    String res = '';
    bool isValid = true;
    for (int i = 0; i < mailList.length; i++) {
      if (mailList[i].contains('@iitk.ac.in')) {
        List split_mailAddress = mailList[i].split('@iitk.ac.in');
        if (split_mailAddress.length != 2 ||
            split_mailAddress[split_mailAddress.length - 1] != '' ||
            split_mailAddress[0] == '') {
          String verifyEmailFormat(List<dynamic> mailList) {
            String res = '';
            for (int i = 0; i < mailList.length; i++) {
              if (mailList[i].contains('@iitk.ac.in')) {
                List split_mailAddress = mailList[i].split('@iitk.ac.in');
                if (split_mailAddress.length != 2 ||
                    split_mailAddress[split_mailAddress.length - 1] != '' ||
                    split_mailAddress[0] == '') {
                  res = 'Email content is badly formatted';
                  break;
                } else {
                  res = 'Correct Format';
                }
              } else {
                res = 'Email content is badly formatted';
                break;
              }
            }
            return res;
          }
        } else {
          res = 'Correct Format';
        }
      } else {
        res = 'Email content is badly formatted';
        break;
      }
    }
    return res;
  }

  String verifyPoll() {
    if (_pollQuestionController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Poll question cannot be empty',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      );
      return 'Badly Formatted';
    } else if (_pollQuestionController.text.length > 180) {
      Fluttertoast.showToast(
        msg: 'Poll question can have only upto 180 characters',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      );
      return 'Badly Formatted';
    }
    for (int i = 0; i < numPollOptions; i++) {
      if (_pollOptionControllers[i].text.isEmpty) {
        Fluttertoast.showToast(
          msg: 'One or more poll options is/are empty',
          textColor: Colors.white,
          backgroundColor: const Color.fromARGB(211, 0, 0, 0),
        );
        return 'Badly Formatted';
      } else if (_pollOptionControllers[i].text.length > 60) {
        Fluttertoast.showToast(
          msg: 'Poll options can have only upto 60 characters',
          textColor: Colors.white,
          backgroundColor: const Color.fromARGB(211, 0, 0, 0),
        );
        return 'Badly Formatted';
      }
    }
    return 'Correct Format';
  }

  Future<bool> isEmailInDatabase(String email) async {
    QuerySnapshot<Map<String, dynamic>> specificIndividualSnap =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
    if (specificIndividualSnap.docs.isEmpty) {
      return false;
    }
    return true;
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

  void _postingConfessionToAdmin(
      bool enableSpecificIndividuals,
      bool enableAnonymousChat,
      bool enablePoll,
      bool postAsAdmin,
      Models.User currentUser) async {
    if (_confessionController.text != '') {
      if (enableSpecificIndividuals &&
          _specificIndividualsController.text == '') {
        Fluttertoast.showToast(
          msg:
              'Please mention email address(es) of individuals (or) disable the option.',
          textColor: Colors.white,
          backgroundColor: const Color.fromARGB(211, 0, 0, 0),
        );
      } else if (enablePoll && verifyPoll() == 'Badly Formatted') {
        return;
      } else {
        setState(
          () => _postingConfession = true,
        );
        List<dynamic> mailList = [];
        String mailVerifyRes = 'not necessary';
        if (enableSpecificIndividuals &&
            _specificIndividualsController.text != '') {
          mailList = _specificIndividualsController.text
              .split(',')
              .map((e) => e.trim())
              .toList();
          mailList.remove(currentUser.email);
          mailVerifyRes = verifyEmailFormat(mailList);
        }
        if (mailVerifyRes != 'not necessary' &&
            mailVerifyRes != 'Correct Format') {
          setState(
            () => _postingConfession = false,
          );
          Fluttertoast.showToast(
            msg: 'Incorrect email format',
            textColor: Colors.white,
            backgroundColor: const Color.fromARGB(211, 0, 0, 0),
          );
          return;
        } else if (mailList.length > 5) {
          setState(() => _postingConfession = false);
          Fluttertoast.showToast(
            msg: 'You can confess upto only 5 individuals at a time.',
            textColor: Colors.white,
            backgroundColor: const Color.fromARGB(211, 0, 0, 0),
          );
          return;
        } else {
          List<String> mailNotExistInDatabaseList = [];
          for (int i = 0; i < mailList.length; i++) {
            if (await isEmailInDatabase(mailList[i]) == false) {
              mailNotExistInDatabaseList.add(mailList[i]);
            }
          }
          if (mailNotExistInDatabaseList.isNotEmpty) {
            setState(
              () => _postingConfession = false,
            );
            mailNotExistInDatabaseList.map((mail) async {
              await sendMail2(
                  reciever_address: mail,
                  mail_subject:
                      "You've received a confession on IITK Confessions App!",
                  mail_content: """
Hello,

Someone has mentioned you in their confession, on [Your App's Name], but we noticed you haven't joined us yet!

IITK Confessions is a unique campus community platform where students like you can connect and share experiences. Don't miss out!
Download the app now to view your message and join the conversation:
[Type IITK Confessions in Google Playstore - it has a ghosted icon]

See you soon!

We sincerely apologize to our iOS users - rest assured, a compatible version of our app is under development.

Best Regards,
Admin team
TeamConfessions IITK
""");
            });
            Fluttertoast.showToast(
              toastLength: Toast.LENGTH_LONG,
              msg:
                  """Following emails dont have accounts yet. Please remove them: $mailNotExistInDatabaseList""",
              textColor: Colors.white,
              backgroundColor: const Color.fromARGB(211, 0, 0, 0),
            );
            Fluttertoast.showToast(
              toastLength: Toast.LENGTH_LONG,
              msg:
                  "Dont worry, we have mailed them an invitation to join our community. You can try again some other time.",
              textColor: Colors.white,
              backgroundColor: const Color.fromARGB(211, 0, 0, 0),
            );
            return;
          }
          String res = '';
          String confession_id = const Uuid().v4();
          Timestamp datePublished = Timestamp.now();
          Map<String, dynamic> userPoll = {
            'question': _pollQuestionController.text,
            'options': {
              '1': {_pollOptionControllers[0].text: []},
              '2': {_pollOptionControllers[1].text: []},
              '3': _pollOptionControllers[2].text.isNotEmpty
                  ? {_pollOptionControllers[2].text: []}
                  : null,
              '4': _pollOptionControllers[3].text.isNotEmpty
                  ? {_pollOptionControllers[3].text: []}
                  : null
            }
          };
          final en.SecureRandom sharedKey = en.SecureRandom(32);
          final sharedSecureKey = en.Key(base64Decode(sharedKey.base64));
          final secureEncrypter = en.Encrypter(en.AES(sharedSecureKey));
          String encryptedUid = secureEncrypter
              .encrypt(currentUser.uid, iv: en.IV.fromBase64('campus12'))
              .base64;
          List<String> encryptedMails = mailList.map((email) {
            return secureEncrypter
                .encrypt(email, iv: en.IV.fromBase64('campus12'))
                .base64;
          }).toList();
          Map<String, pt.RSAPublicKey> specificPublicKeys =
              mailList.isNotEmpty ? await fetchPublicKeys(mailList) : {};
          List<String> encryptedSharedKeys = [];
          for (int i = 0; i < mailList.length; i++) {
            final RSAencrypter = en.Encrypter(
                en.RSA(publicKey: specificPublicKeys[mailList[i]]));
            encryptedSharedKeys
                .add(RSAencrypter.encrypt(sharedSecureKey.base64).base64);
          }
          final encrypter = en.Encrypter(en.RSA(publicKey: widget.publicKey));
          encryptedSharedKeys
              .add(encrypter.encrypt(sharedSecureKey.base64).base64);
          Models.Confession newConfession = Models.Confession(
              user_uid: encryptedUid,
              avatarURL: _auth.currentUser!.photoURL!,
              confession_no: widget.confessionNum,
              confessionId: confession_id,
              confession: _confessionController.text.trim(),
              enableAnonymousChat: enableAnonymousChat,
              enableSpecificIndividuals: enableSpecificIndividuals,
              specificIndividuals: encryptedMails,
              datePublished: datePublished,
              reactions: <String, dynamic>{
                'like': [],
                'love': [],
                'haha': [],
                'wink': [],
                'woah': [],
                'sad': [],
                'angry': []
              },
              chatRoomIDs: {},
              enablePoll: _enablePoll,
              poll: _enablePoll ? userPoll : null,
              encryptedSharedKeys: encryptedSharedKeys,
              notifyCountSIs: 0,
              adminPost: postAsAdmin);
          res = await _firestoreMethods.postConfessionToAdmin(widget.admins,
              newConfession, currentUser, secureEncrypter, sharedSecureKey);
          setState(
            () => _postingConfession = false,
          );
          setState(
            () => _notifyingAdmins = true,
          );
          QuerySnapshot adminDocs = await _firestore
              .collection('users')
              .where('uid', whereIn: widget.admins)
              .get();
          for (var doc in adminDocs.docs) {
            Map<dynamic, dynamic> notifyAdminData = {
              'to': doc['token'],
              'priority': 'high',
              'data': {
                'title': 'Confessions',
                'body': "A confession is waiting for your approval...",
                'type': 'admin approval',
              }
            };
            await http.post(
              Uri.parse('https://fcm.googleapis.com/fcm/send'),
              body: jsonEncode(notifyAdminData),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization':
                    'key=AAAAtA6V0JA:APA91bEwrE_GBMBe-aWVap09EcR0H9peWaMIY3nM9ewzsxCxjYL9gbBuGPIIPvs-jStFGTMnFI6cq7Lw_bH3yaRuuwymAVppZO1Y6fGI45QgscvFzEfYXHIrn9on6b68y1F59Jg6KweO'
              },
            );
          }
          setState(
            () => _notifyingAdmins = false,
          );
          Navigator.of(context).pop();
          Fluttertoast.showToast(
            msg: res,
            textColor: Colors.white,
            backgroundColor: const Color.fromARGB(211, 0, 0, 0),
          );
        }
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Confession field should not be empty',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Models.User currentUser = Provider.of<UserProvider>(context).getUser!;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(239, 254, 254, 254),
        appBar: AppBar(
          toolbarHeight: 65.0,
          leading: Container(),
          leadingWidth: 0.0,
          titleSpacing: 0.0,
          title: Container(
            width: double.infinity,
            height: 65.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 26, 123, 203),
                  Colors.lightBlue,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    if (!_postingConfession && !_notifyingAdmins) {
                      Navigator.of(context).pop();
                    } else {
                      Fluttertoast.showToast(
                        msg:
                            'Have patience. Your confession is in the posting process.',
                        textColor: Colors.white,
                        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
                      );
                    }
                  },
                  style: ButtonStyle(
                      overlayColor: MaterialStateProperty.all(
                          const Color.fromARGB(112, 244, 67, 54)),
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 20.0)
                              .copyWith(right: 10.0, left: 8.0))),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        color: Color.fromARGB(255, 241, 64, 51),
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5),
                  ),
                ),
                Text(
                  'New Confession',
                  style: GoogleFonts.secularOne(
                    textStyle: const TextStyle(
                        fontSize: 23.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    return showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          titlePadding:
                              const EdgeInsets.symmetric(horizontal: 10.0)
                                  .copyWith(top: 15.0),
                          title: Column(
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                      fontSize: 15.0, color: Colors.black),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text:
                                            'Your confession will be sent for review to the admins. To maintain your anonymity, please note that you will not receive a notification upon approval. So check back often to see if it has been posted. With '),
                                    TextSpan(
                                      text: 'end-to-end encryption',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(
                                        text:
                                            ' securing all information, your identity will remain strictly confidential.'),
                                  ],
                                ),
                              ),
                              _enableSpecificIndividuals
                                  ? RichText(
                                      text: const TextSpan(children: <TextSpan>[
                                        TextSpan(
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold),
                                            text: '\nNote: '),
                                        TextSpan(
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w400),
                                            text:
                                                'Once your confession is approved, you will have an option to notify specific individuals from your confession page.')
                                      ]),
                                    )
                                  : Container(),
                            ],
                          ),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    if (await checkConnectivity()) {
                                      if (!_postingConfession &&
                                          !_notifyingAdmins) {
                                        _postingConfessionToAdmin(
                                            _enableSpecificIndividuals,
                                            _enableAnonymousChat,
                                            _enablePoll,
                                            _postAsAdmin,
                                            currentUser);
                                      } else {
                                        Fluttertoast.showToast(
                                          msg:
                                              'Have patience. Your confession is being posted.',
                                          textColor: Colors.white,
                                          backgroundColor: const Color.fromARGB(
                                              211, 0, 0, 0),
                                        );
                                      }
                                    } else {
                                      Fluttertoast.showToast(
                                        msg:
                                            'Please check your internet connection',
                                        textColor: Colors.white,
                                        backgroundColor:
                                            const Color.fromARGB(211, 0, 0, 0),
                                      );
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 10.0),
                                    child: Text(
                                      'Confess',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 16, 68, 111),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17.0),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      },
                    );
                  },
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 20.0)
                              .copyWith(right: 10.0, left: 10.0)),
                      overlayColor: MaterialStateProperty.all(
                          const Color.fromARGB(120, 249, 249, 249))),
                  child: const Text(
                    'Confess',
                    style: TextStyle(
                        color: Color.fromARGB(255, 16, 68, 111),
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: _postingConfession
            ? const FrontLoadingPage()
            : _notifyingAdmins
                ? const FrontLoadingPage()
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7.0, vertical: 5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Confess to specific individuals',
                                style: GoogleFonts.secularOne(
                                  textStyle: const TextStyle(fontSize: 17.0),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return MediaQuery(
                                            data: MediaQuery.of(context)
                                                .copyWith(textScaleFactor: 1.0),
                                            child: const SimpleDialog(
                                              titlePadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 15.0,
                                                      vertical: 15.0),
                                              title: Text(
                                                """Want to confess to a specific person(s)?

Click on the checkbox and enter their emails in the format shown below. Don't worry, everything is end-to-end encrypted. Nobody other than you can see these details, not even admins! Your privacy is of utmost importance to us.""",
                                                style: TextStyle(
                                                    fontSize: 15.0,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                          );
                                        });
                                  },
                                  child: Transform.scale(
                                    scale: 1.2,
                                    child: CircleAvatar(
                                      radius: 8.0,
                                      backgroundColor: Colors.black,
                                      child: CircleAvatar(
                                        radius: 6.5,
                                        backgroundColor: const Color.fromARGB(
                                            239, 254, 254, 254),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 0.0),
                                          child: Text(
                                            '?',
                                            style: GoogleFonts.secularOne(
                                              textStyle: const TextStyle(
                                                  fontSize: 11.0),
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(child: Container()),
                              Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  activeColor:
                                      const Color.fromARGB(255, 45, 139, 216),
                                  checkColor: Colors.white,
                                  splashRadius: 0.0,
                                  value: _enableSpecificIndividuals,
                                  onChanged: (value) {
                                    setState(() {
                                      _enableSpecificIndividuals =
                                          !_enableSpecificIndividuals;
                                      if (!_enableSpecificIndividuals) {
                                        _enableAnonymousChat = false;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              height: _enableSpecificIndividuals ? null : 0.0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              child: TextField(
                                textInputAction: TextInputAction.done,
                                controller: _specificIndividualsController,
                                keyboardType: TextInputType.multiline,
                                style: const TextStyle(fontSize: 17.0),
                                cursorColor: Colors.black,
                                cursorHeight: 25.0,
                                maxLines: 3,
                                focusNode: _speficiIndividualsFocusNode,
                                enabled: _enableSpecificIndividuals,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 10.0),
                                  hintText:
                                      'Format: email1, email2, ...(only @iitk.ac.in)',
                                  hintStyle: TextStyle(fontSize: 15.0),
                                  fillColor: Colors.white,
                                  filled: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(width: 1.2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.blue, width: 2.0),
                                  ),
                                ),
                                enableSuggestions: false,
                              ),
                            ),
                          ),
                          _enableSpecificIndividuals
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                          horizontal: 5.0)
                                      .copyWith(top: 5.0),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          "* Your confidentiality is our utmost priority. Even admins wont be able to see these details.",
                                          style: GoogleFonts.secularOne(
                                            textStyle: const TextStyle(
                                                fontSize: 13.0,
                                                color: Color.fromARGB(
                                                    255, 224, 58, 46)),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : Container(),
                          const SizedBox(
                            height: 0.0,
                          ),
                          Row(
                            children: [
                              Text(
                                'Enable anonymous chat',
                                style: GoogleFonts.secularOne(
                                  textStyle: const TextStyle(fontSize: 17.0),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) => MediaQuery(
                                              data: MediaQuery.of(context)
                                                  .copyWith(
                                                      textScaleFactor: 1.0),
                                              child: const SimpleDialog(
                                                titlePadding:
                                                    EdgeInsets.all(15.0),
                                                title: Text(
                                                  """Confessing to specific Individual(s)?

You can now engage them in a private and anonymous conversation after they've seen your confession. Activate this feature to get started. 

All chats are fully encrypted from end to end. Only you and the recipient can see the chat details.
                          
Note: Only the recipient has the option to create a chat room, providing them the flexibility to engage if they wish.""",
                                                  style: TextStyle(
                                                      fontSize: 15.0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                            ));
                                  },
                                  child: Transform.scale(
                                    scale: 1.2,
                                    child: CircleAvatar(
                                      radius: 8.0,
                                      backgroundColor: Colors.black,
                                      child: CircleAvatar(
                                        radius: 6.5,
                                        backgroundColor: const Color.fromARGB(
                                            239, 254, 254, 254),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 0.0),
                                          child: Text(
                                            '?',
                                            style: GoogleFonts.secularOne(
                                              textStyle: const TextStyle(
                                                  fontSize: 11.0),
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(child: Container()),
                              Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  activeColor:
                                      const Color.fromARGB(255, 45, 139, 216),
                                  checkColor: Colors.white,
                                  splashRadius: 0.0,
                                  value: _enableAnonymousChat,
                                  onChanged: (value) => setState(() {
                                    if (_enableSpecificIndividuals) {
                                      _enableAnonymousChat =
                                          !_enableAnonymousChat;
                                    } else {
                                      _enableAnonymousChat = false;
                                      Fluttertoast.showToast(
                                        msg:
                                            'You need to fill in specific individual details first.',
                                        textColor: Colors.white,
                                        backgroundColor:
                                            const Color.fromARGB(211, 0, 0, 0),
                                      );
                                    }
                                  }),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 0.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Ask a public poll?',
                                      style: GoogleFonts.secularOne(
                                        textStyle:
                                            const TextStyle(fontSize: 17.0),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      child: InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => MediaQuery(
                                              data: MediaQuery.of(context)
                                                  .copyWith(
                                                      textScaleFactor: 1.0),
                                              child: const SimpleDialog(
                                                titlePadding:
                                                    EdgeInsets.all(15.0),
                                                title: Text(
                                                  """Want to ask a question to the public related to your confession?

Activate this feature!""",
                                                  style: TextStyle(
                                                      fontSize: 15.0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Transform.scale(
                                          scale: 1.2,
                                          child: CircleAvatar(
                                            radius: 8.0,
                                            backgroundColor: Colors.black,
                                            child: CircleAvatar(
                                              radius: 6.5,
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      239, 254, 254, 254),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 0.0),
                                                child: Text(
                                                  '?',
                                                  style: GoogleFonts.secularOne(
                                                    textStyle: const TextStyle(
                                                        fontSize: 11.0),
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Flexible(child: Container()),
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        activeColor: const Color.fromARGB(
                                            255, 45, 139, 216),
                                        checkColor: Colors.white,
                                        splashRadius: 0.0,
                                        value: _enablePoll,
                                        onChanged: (value) => setState(
                                          () => _enablePoll = !_enablePoll,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    height: _enablePoll ? null : 0.0,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0, vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: const Color.fromARGB(
                                              225, 0, 0, 0),
                                          width: 1.0),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10.0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Question:',
                                              style: GoogleFonts.secularOne(
                                                textStyle: const TextStyle(
                                                    fontSize: 17.0),
                                              ),
                                            ),
                                            Flexible(child: Container()),
                                            Text(
                                              '${_pollQuestionController.text.length}/180',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 58, 58, 58),
                                                  fontSize: 12.0),
                                            )
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 5.0),
                                          child: Transform.scale(
                                            scaleY: 1.0,
                                            child: RawScrollbar(
                                              thumbColor: Colors.black38,
                                              child: TextField(
                                                controller:
                                                    _pollQuestionController,
                                                maxLines: 4,
                                                keyboardType:
                                                    TextInputType.text,
                                                decoration:
                                                    const InputDecoration(
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 10.0,
                                                          vertical: 5.0),
                                                  hintText:
                                                      'Write your question here',
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.black,
                                                        width: 1.0),
                                                  ),
                                                ),
                                                onChanged: (value) =>
                                                    setState(() {}),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Options:',
                                              style: GoogleFonts.secularOne(
                                                textStyle: const TextStyle(
                                                    fontSize: 17.0),
                                              ),
                                            ),
                                            Flexible(child: Container()),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (numPollOptions > 2 &&
                                                        numPollOptions <= 4) {
                                                      setState(
                                                        () => numPollOptions--,
                                                      );
                                                    } else if (numPollOptions ==
                                                        2) {
                                                      Fluttertoast.showToast(
                                                        msg:
                                                            'You need to fill up atleast two options',
                                                        textColor: Colors.white,
                                                        backgroundColor:
                                                            const Color
                                                                    .fromARGB(
                                                                211, 0, 0, 0),
                                                      );
                                                    } else {
                                                      setState(
                                                        () =>
                                                            numPollOptions = 2,
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color.fromARGB(
                                                          255, 45, 139, 216),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(15.0),
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.remove,
                                                      color: Colors.white,
                                                      size: 18.0,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 10.0),
                                                  child: Text(
                                                    numPollOptions.toString(),
                                                    style:
                                                        GoogleFonts.secularOne(
                                                      textStyle:
                                                          const TextStyle(
                                                              fontSize: 17.0),
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    if (numPollOptions >= 2 &&
                                                        numPollOptions < 4) {
                                                      setState(
                                                        () => numPollOptions++,
                                                      );
                                                    } else if (numPollOptions ==
                                                        4) {
                                                      Fluttertoast.showToast(
                                                        msg:
                                                            'You can have maximum of 4 options',
                                                        textColor: Colors.white,
                                                        backgroundColor:
                                                            const Color
                                                                    .fromARGB(
                                                                211, 0, 0, 0),
                                                      );
                                                    } else {
                                                      setState(
                                                        () =>
                                                            numPollOptions = 2,
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color.fromARGB(
                                                          255, 45, 139, 216),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(15.0),
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                      size: 18.0,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: numPollOptions,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 1.0),
                                              child: Transform.scale(
                                                scaleY: 1.0,
                                                child: Stack(
                                                    alignment:
                                                        Alignment.topRight,
                                                    children: [
                                                      TextField(
                                                        controller:
                                                            _pollOptionControllers[
                                                                index],
                                                        onChanged: (value) =>
                                                            setState(() {}),
                                                        maxLines: 1,
                                                        keyboardType:
                                                            TextInputType.text,
                                                        decoration:
                                                            InputDecoration(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      10.0),
                                                          hintText:
                                                              'Option ${index + 1}',
                                                          border:
                                                              const OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    color: Colors
                                                                        .black,
                                                                    width: 1.0),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 5.0,
                                                                top: 2.0),
                                                        child: Text(
                                                          '${_pollOptionControllers[index].text.length}/60',
                                                          style:
                                                              const TextStyle(
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          58,
                                                                          58,
                                                                          58),
                                                                  fontSize:
                                                                      12.0),
                                                        ),
                                                      ),
                                                    ]),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Write your confession here:',
                                style: GoogleFonts.secularOne(
                                  textStyle: const TextStyle(fontSize: 17.0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 3.0,
                          ),
                          RawScrollbar(
                            thickness: 5.0,
                            thumbColor: const Color.fromARGB(81, 0, 0, 0),
                            child: TextField(
                              textInputAction: TextInputAction.done,
                              controller: _confessionController,
                              keyboardType: TextInputType.text,
                              cursorColor: Colors.black,
                              cursorHeight: 25.0,
                              maxLines:
                                  MediaQuery.of(context).size.height ~/ 36,
                              decoration: const InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                hintText:
                                    'Please be aware that when confessing, it is important to adhere to ethical practices. DO NOT include any sensitive information in your confession.',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 12.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.blue, width: 2.0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "* Your confession will be sent for review to the admins. It will be publicly displayed once it is approved.",
                                  style: GoogleFonts.secularOne(
                                    textStyle: const TextStyle(
                                        fontSize: 13.0,
                                        color:
                                            Color.fromARGB(255, 224, 58, 46)),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 7.0),
                                  width: 40.0,
                                  height: 1.0,
                                  color: const Color.fromARGB(150, 0, 0, 0),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 0.0),
                                  child: const Text(
                                    'End-to-end encrypted',
                                    style: TextStyle(
                                        color: Color.fromARGB(150, 0, 0, 0),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15.0),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 7.0),
                                  width: 40.0,
                                  height: 1.0,
                                  color: const Color.fromARGB(150, 0, 0, 0),
                                ),
                              ],
                            ),
                          ),
                          widget.admins.contains(_auth.currentUser!.uid)
                              ? Row(
                                  children: [
                                    Text(
                                      'Post as an admin',
                                      style: GoogleFonts.secularOne(
                                        textStyle:
                                            const TextStyle(fontSize: 17.0),
                                      ),
                                    ),
                                    Flexible(child: Container()),
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        activeColor: const Color.fromARGB(
                                            255, 45, 139, 216),
                                        checkColor: Colors.white,
                                        splashRadius: 0.0,
                                        value: _postAsAdmin,
                                        onChanged: (value) => setState(() {
                                          _postAsAdmin = !_postAsAdmin;
                                        }),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
