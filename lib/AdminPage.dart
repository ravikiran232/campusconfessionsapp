import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:untitled2/AdminConfessionPage.dart';
import 'models.dart' as Models;

class AdminPage extends StatefulWidget {
  List<dynamic> admins;
  String primaryAdmin;
  RSAPrivateKey privateKey;
  RSAPublicKey publicKey;
  AdminPage(
      {super.key,
      required this.admins,
      required this.primaryAdmin,
      required this.publicKey,
      required this.privateKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
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
              onPressed: () => {Navigator.of(context).pop()},
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
              gradient: LinearGradient(colors: [
                Color.fromARGB(255, 239, 181, 9),
                Color.fromARGB(255, 199, 151, 5)
              ], begin: Alignment.centerLeft, end: Alignment.centerRight),
            ),
            child: Row(
              children: [
                Text(
                  'Admin Page',
                  style: GoogleFonts.secularOne(
                    textStyle: const TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 249, 249, 249),
                        letterSpacing: 0.5),
                  ),
                ),
                Flexible(child: Container()),
                _auth.currentUser!.uid == widget.primaryAdmin
                    ? IconButton(
                        onPressed: () async {
                          QuerySnapshot<Map<String, dynamic>> adminSnap =
                              await _firestore
                                  .collection('users')
                                  .where('uid', whereIn: widget.admins)
                                  .get();
                          List<String> adminMails = [];
                          for (int i = 0; i < adminSnap.docs.length; i++) {
                            adminMails.add(adminSnap.docs[i]['email']);
                          }
                          showDialog(
                              context: context,
                              builder: (context) {
                                return MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(textScaleFactor: 1.0),
                                  child: SimpleDialog(
                                    titlePadding: const EdgeInsets.symmetric(
                                        horizontal: 10.0, vertical: 15.0),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15.0,
                                    ).copyWith(bottom: 15.0),
                                    title: Row(children: [
                                      const Text(
                                        'Admins',
                                      ),
                                      Flexible(child: Container()),
                                    ]),
                                    children: adminMails.map((mail) {
                                      return GestureDetector(
                                        child: Row(
                                          children: [
                                            Text(
                                              mail,
                                              style: const TextStyle(
                                                  fontSize: 17.0,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Flexible(child: Container()),
                                            mail == _auth.currentUser!.email
                                                ? Text(
                                                    '(You)',
                                                    style: const TextStyle(
                                                        fontSize: 12.0),
                                                  )
                                                : Container()
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              });
                        },
                        icon: const Icon(
                          Icons.group,
                          size: 27.0,
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ),
        body: StreamBuilder(
          stream: _firestore
              .collection('waitlist')
              .orderBy('confession.datePublished', descending: false)
              .snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.none) {
              return const Center(
                child: Text('Check your internet connection'),
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 4, 151, 219),
                ),
              );
            } else {
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No confessions to approve'),
                );
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        if (snapshot.data!.docs[index]
                                .data()
                                .containsKey('confession') &&
                            snapshot.data!.docs[index]
                                .data()
                                .containsKey('user')) {
                          Map<String, dynamic> confessionMap =
                              snapshot.data!.docs[index]['confession'];
                          Map<String, dynamic> ownerMap =
                              snapshot.data!.docs[index]['user'];
                          Models.Confession confession = Models.Confession(
                              confessionId: confessionMap['confessionId'],
                              user_uid: confessionMap['user_uid'], //encrypted
                              avatarURL: confessionMap['avatarURL'],
                              confession: confessionMap['confession'],
                              enableAnonymousChat:
                                  confessionMap['enableAnonymousChat'],
                              enableSpecificIndividuals:
                                  confessionMap['enableSpecificIndividuals'],
                              views: confessionMap['views'],
                              upvotes: confessionMap['upvotes'],
                              downvotes: confessionMap['downvotes'],
                              reactions: confessionMap['reactions'],
                              chatRoomIDs: confessionMap['chatRoomIDs'], //???
                              datePublished: confessionMap['datePublished'],
                              specificIndividuals: confessionMap[
                                  'specificIndividuals'], //encrypted
                              seenBySIs: confessionMap['seenBySIs'], //???
                              enablePoll: confessionMap['enablePoll'],
                              poll: confessionMap['poll'],
                              encryptedSharedKeys:
                                  confessionMap['encryptedSharedKeys'],
                              notifyCountSIs: confessionMap['notifyCountSIs'],
                              adminPost: confessionMap['adminPost']);
                          Models.User owner = Models.User(
                              //encrypted
                              uid: ownerMap['uid'], //encrypted
                              avatarURL: ownerMap['avatarURL'],
                              email: 'None',
                              token: 'None'); //encrypted
                          // final adminEncryptedSharedKey = snapshot
                          //     .data!.docs[index]['adminEncryptedSharedKey'];
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => AdminConfessionPage(
                                publicKey: widget.publicKey,
                                privateKey: widget.privateKey,
                                confession: confession,
                                owner: owner,
                                isApproved: snapshot.data!.docs[index]
                                    ['approved'],
                              ),
                            ),
                          );
                        } else {
                          Fluttertoast.showToast(
                            msg: 'Unable to open this confession',
                            textColor: Colors.white,
                            backgroundColor: const Color.fromARGB(211, 0, 0, 0),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3.0)
                            .copyWith(top: 5.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10.0),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black, width: 1.0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                snapshot.data!.docs[index]['approved']
                                    ? const Text(
                                        'Approved',
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 17.0,
                                            fontWeight: FontWeight.w600),
                                      )
                                    : const Text(
                                        'Pending',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 17.0,
                                            fontWeight: FontWeight.w600),
                                      ),
                                Flexible(child: Container()),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 1.0),
                                  child: Text(
                                    'Requested on: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.0),
                                  ),
                                ),
                                snapshot.data!.docs[index]
                                            .data()
                                            .containsKey('confession') &&
                                        snapshot.data!.docs[index]['confession']
                                            .containsKey('datePublished')
                                    ? Row(
                                        children: [
                                          Text(
                                            DateFormat.jm().format(
                                              snapshot
                                                  .data!
                                                  .docs[index]['confession']
                                                      ['datePublished']
                                                  .toDate(),
                                            ),
                                            style:
                                                const TextStyle(fontSize: 13.0),
                                          ),
                                          const Text(', '),
                                          Text(
                                            DateFormat.MEd().format(
                                              snapshot
                                                  .data!
                                                  .docs[index]['confession']
                                                      ['datePublished']
                                                  .toDate(),
                                            ),
                                            style:
                                                const TextStyle(fontSize: 13.0),
                                          )
                                        ],
                                      )
                                    : const Text(
                                        'Undefined',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 15.0),
                                      ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 5.0),
                              child: Text(
                                snapshot.data!.docs[index]['confession']
                                    ['confession'],
                                style: const TextStyle(
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            }
          },
        ),
      ),
    );
  }
}
