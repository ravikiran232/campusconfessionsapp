import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/firestore_methods.dart';
import 'mail_servicesII.dart';
import 'models.dart' as Models;
import 'package:http/http.dart' as http;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class AdminConfessionPage extends StatefulWidget {
  Models.Confession confession;
  Models.User owner;
  bool isApproved;
  RSAPublicKey publicKey;
  RSAPrivateKey privateKey;
  AdminConfessionPage(
      {super.key,
      required this.confession,
      required this.owner,
      this.isApproved = false,
      required this.publicKey,
      required this.privateKey});

  @override
  State<AdminConfessionPage> createState() => _AdminConfessionPageState();
}

class _AdminConfessionPageState extends State<AdminConfessionPage> {
  final FirestoreMethods _firestoreMethods = FirestoreMethods();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool postingConfession = false;

  int confessionNum = -1;

  @override
  void initState() {
    super.initState();
    getConfessionNum();
  }

  Future<void> getConfessionNum() async {
    try {
      _firestore.collection('users').doc('admins').get().then((doc) {
        if (doc.exists) {
          setState(() => confessionNum = doc['confessionCount']);
        }
      });
    } catch (err) {
      Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg:
            'Failed to fetch confession number. Please go back and come again.',
        textColor: Colors.black,
        backgroundColor: const Color.fromARGB(226, 255, 255, 255),
      );
    }
  }

  void approveConfession() async {
    if (confessionNum == -1) {
      Fluttertoast.showToast(
        msg:
            'Failed to fetch confession number. Please go back and come again.',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      );
    } else if (widget.isApproved) {
      Fluttertoast.showToast(
        msg:
            'Confession is already approved. Click on the discard button to delete it from waitlist.',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      );
    } else {
      try {
        setState(
          () => postingConfession = true,
        );
        Timestamp datePublished = Timestamp.now();
        widget.confession.datePublished = datePublished;
        widget.confession.confession_no = confessionNum;
        String confessionRes =
            await _firestoreMethods.postConfessionFromAdmin(widget.confession);
        await _firestore
            .collection('users')
            .doc('admins')
            .update({'confessionCount': FieldValue.increment(1)});
        setState(
          () => postingConfession = false,
        );
        Navigator.of(context).pop();
        Fluttertoast.showToast(
          msg: confessionRes,
          textColor: Colors.white,
          backgroundColor: const Color.fromARGB(211, 0, 0, 0),
        );
      } catch (err) {
        Fluttertoast.showToast(
          msg: err.toString(),
          textColor: Colors.white,
          backgroundColor: const Color.fromARGB(211, 0, 0, 0),
        );
      }
    }
  }

  Future<void> discardConfession() async {
    try {
      setState(
        () => postingConfession = true,
      );
      await _firestore
          .collection('waitlist')
          .doc(widget.confession.confessionId)
          .delete();
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: 'Confession successfully discarded',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      );
    } catch (err) {
      Fluttertoast.showToast(
        msg: 'Unable to discard confession. Please try again.',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      );
    }
    setState(
      () => postingConfession = false,
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

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: WillPopScope(
        onWillPop: () async {
          return !postingConfession;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.amber,
            automaticallyImplyLeading: false,
            elevation: 5.0,
            titleSpacing: 0.0,
            leading: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                Color.fromARGB(255, 236, 178, 6),
                Color.fromARGB(255, 236, 178, 6)
              ], begin: Alignment.centerLeft, end: Alignment.centerRight)),
              child: IconButton(
                onPressed: () =>
                    postingConfession ? null : Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back,
                  size: 30.0,
                  color: postingConfession
                      ? Colors.grey
                      : const Color.fromARGB(255, 249, 249, 249),
                ),
              ),
            ),
            title: Container(
              height: 57.0,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color.fromARGB(255, 239, 181, 9),
                  Color.fromARGB(255, 199, 151, 5)
                ], begin: Alignment.centerLeft, end: Alignment.centerRight),
              ),
              child: Row(
                children: [
                  Flexible(child: Container()),
                ],
              ),
            ),
          ),
          body: postingConfession
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 236, 178, 6),
                  ),
                )
              : SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Requested on: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 20.0),
                            ),
                            Text(
                              DateFormat.jm().format(
                                  widget.confession.datePublished!.toDate()),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 15.0),
                            ),
                            const Text(', '),
                            Text(
                              DateFormat.MMMMd().format(
                                  widget.confession.datePublished!.toDate()),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 15.0),
                            ),
                            const Text(', '),
                            Text(
                              DateFormat.y().format(
                                  widget.confession.datePublished!.toDate()),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 15.0),
                            ),
                            Flexible(child: Container())
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Confession number: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20.0),
                              ),
                              Text(
                                '#',
                                style: GoogleFonts.secularOne(
                                  textStyle: const TextStyle(fontSize: 30.0),
                                ),
                              ),
                              SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.015,
                              ),
                              Container(
                                height: 40.0,
                                width: 90.0,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 174, 174, 174),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      confessionNum.toString(),
                                      style: GoogleFonts.caveat(
                                        textStyle: const TextStyle(
                                          fontSize: 30.0,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Confession: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 23.0),
                                    ),
                                    widget.confession.adminPost
                                        ? const Text(
                                            '(From Admin)',
                                            style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 243, 183, 5),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 17.0),
                                          )
                                        : Container(),
                                    Flexible(child: Container())
                                  ],
                                ),
                              ),
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 10.0),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black, width: 1.0)),
                                child: RawScrollbar(
                                  thumbColor: const Color.fromARGB(93, 0, 0, 0),
                                  thickness: 3.0,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      widget.confession.confession!,
                                      style: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        widget.confession.enablePoll
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Poll:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 23.0),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 0.0, vertical: 10.0),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0, vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: Colors.black, width: 1.0),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(0.0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 5.0),
                                          child: Text(
                                            widget.confession.poll!['question'],
                                            style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        widget.confession.poll!['options']
                                                    ['1'] !=
                                                null
                                            ? Container(
                                                width: double.infinity,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5.0),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 5.0),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.black,
                                                      width: 1.0),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(5.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget
                                                      .confession
                                                      .poll!['options']['1']
                                                      .keys
                                                      .toList()[0],
                                                  style: const TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              )
                                            : Container(),
                                        widget.confession.poll!['options']
                                                    ['2'] !=
                                                null
                                            ? Container(
                                                width: double.infinity,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5.0),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 5.0),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.black,
                                                      width: 1.0),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(5.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget
                                                      .confession
                                                      .poll!['options']['2']
                                                      .keys
                                                      .toList()[0],
                                                  style: const TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              )
                                            : Container(),
                                        widget.confession.poll!['options']
                                                    ['3'] !=
                                                null
                                            ? Container(
                                                width: double.infinity,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5.0),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 5.0),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.black,
                                                      width: 1.0),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(5.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget
                                                      .confession
                                                      .poll!['options']['3']
                                                      .keys
                                                      .toList()[0],
                                                  style: const TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              )
                                            : Container(),
                                        widget.confession.poll!['options']
                                                    ['4'] !=
                                                null
                                            ? Container(
                                                width: double.infinity,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5.0),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 5.0),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.black,
                                                      width: 1.0),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(5.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget
                                                      .confession
                                                      .poll!['options']['4']
                                                      .keys
                                                      .toList()[0],
                                                  style: const TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              )
                                            : Container()
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Container(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(child: Container()),
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: TextButton(
                                onPressed: () async {
                                  if (await checkConnectivity()) {
                                    discardConfession();
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
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.red),
                                ),
                                child: const Text(
                                  'Discard',
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 0.0),
                              child: TextButton(
                                onPressed: () async {
                                  if (await checkConnectivity()) {
                                    approveConfession();
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
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.green)),
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
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
