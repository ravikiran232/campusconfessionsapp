import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:untitled2/firestore_methods.dart';
import 'package:untitled2/models.dart' as Models;
import 'package:untitled2/user_confession_page.dart';
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class RankCardIII extends StatefulWidget {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  int rank;
  Models.Confession confession;
  RankCardIII(
      {super.key,
      required this.publicKey,
      required this.privateKey,
      required this.confession,
      required this.rank});

  @override
  State<RankCardIII> createState() => _RankCardIIIState();
}

class _RankCardIIIState extends State<RankCardIII> {
  final FirestoreMethods _firestoreMethods = FirestoreMethods();

  String? confessionSharedKey;
  en.Encrypter? encrypter;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final en.Encrypter decrypter =
        en.Encrypter(en.RSA(privateKey: widget.privateKey));
    for (int i = 0; i < widget.confession.encryptedSharedKeys!.length; i++) {
      try {
        confessionSharedKey = decrypter.decrypt(
            en.Encrypted.fromBase64(widget.confession.encryptedSharedKeys![i]));
        encrypter =
            en.Encrypter(en.AES(en.Key.fromBase64(confessionSharedKey!)));
      } catch (err) {}
    }

    return Container(
      padding: const EdgeInsets.only(top: 7.0),
      width: MediaQuery.of(context).size.width,
      height: 90.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => UserConfessionPage(
                      publicKey: widget.publicKey,
                      privateKey: widget.privateKey,
                      confession: widget.confession,
                      avatarURL: widget.confession.avatarURL,
                      firstTime: widget.confession.views
                              .contains(_auth.currentUser!.uid)
                          ? false
                          : true,
                    ),
                  ),
                );
                await _firestoreMethods.viewedConfession(
                    widget.confession, encrypter);
              },
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.rank}',
                          style: GoogleFonts.secularOne(
                            textStyle: const TextStyle(
                              fontSize: 25.0,
                              color: Color.fromARGB(255, 35, 35, 35),
                            ),
                          ),
                        ),
                        Text(
                          widget.rank == 1
                              ? 'st'
                              : widget.rank == 2
                                  ? 'nd'
                                  : widget.rank == 3
                                      ? 'rd'
                                      : 'th',
                          style: GoogleFonts.secularOne(
                            textStyle: const TextStyle(
                              fontSize: 17.0,
                              color: Color.fromARGB(255, 35, 35, 35),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${widget.confession.confession_no}',
                          style: GoogleFonts.caveat(
                            textStyle: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 35, 35, 35),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 3.0,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: Text(
                            '${widget.confession.confession}',
                            style: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w400,
                              color: Color.fromARGB(255, 28, 28, 28),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Divider(
              thickness: 1.0,
              color: Color.fromARGB(168, 41, 41, 41),
            ),
          )
        ],
      ),
    );
  }
}
