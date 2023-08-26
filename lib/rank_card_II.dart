import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:untitled2/firestore_methods.dart';
import 'package:untitled2/models.dart';
import 'package:untitled2/user_confession_page.dart';
import 'package:untitled2/user_provider.dart';
import 'models.dart' as Models;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class RankCardII extends StatefulWidget {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  String asset_path;
  Color borderColor;
  Color gradColor1;
  Color gradColor2;
  int rank;
  bool _tapped = false;
  Confession? confession;
  RankCardII(
      {super.key,
      required this.publicKey,
      required this.privateKey,
      required this.asset_path,
      required this.confession,
      this.borderColor = Colors.white,
      this.gradColor1 = Colors.white,
      this.gradColor2 = Colors.white,
      this.rank = -1});

  @override
  State<RankCardII> createState() => _RankCardIIState();
}

class _RankCardIIState extends State<RankCardII> {
  final FirestoreMethods _firestoreMethods = FirestoreMethods();

  String? confessionSharedKey;
  en.Encrypter? encrypter;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    if (widget.confession != null) {
      final en.Encrypter decrypter =
          en.Encrypter(en.RSA(privateKey: widget.privateKey));
      for (int i = 0; i < widget.confession!.encryptedSharedKeys!.length; i++) {
        try {
          confessionSharedKey = decrypter.decrypt(en.Encrypted.fromBase64(
              widget.confession!.encryptedSharedKeys![i]));
          encrypter =
              en.Encrypter(en.AES(en.Key.fromBase64(confessionSharedKey!)));
        } catch (err) {}
      }
    }

    return InkWell(
      onTap: () async {
        if (widget.confession != null) {
          setState(
            () => widget._tapped = true,
          );
          await Future.delayed(
            const Duration(milliseconds: 80),
          );
          Navigator.push(
            context,
            PageTransition(
                duration: const Duration(milliseconds: 400),
                child: UserConfessionPage(
                  publicKey: widget.publicKey,
                  privateKey: widget.privateKey,
                  confession: widget.confession!,
                  avatarURL: widget.confession!.avatarURL,
                  rank: widget.rank,
                  firstTime:
                      widget.confession!.views.contains(_auth.currentUser!.uid)
                          ? false
                          : true,
                ),
                type: PageTransitionType.fade),
          );
          setState(
            () => widget._tapped = false,
          );
          await _firestoreMethods.viewedConfession(
              widget.confession!, encrypter);
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.09,
        child: Row(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.07,
              height: MediaQuery.of(context).size.height * 0.07,
              margin: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
              ),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.asset_path),
                ),
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: widget._tapped ? 0.85 : 1,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: -22.0,
                    child: Transform.rotate(
                      angle: 4.71,
                      child: Container(
                        width: MediaQuery.of(context).size.height * 0.09,
                        height: MediaQuery.of(context).size.width * 0.07,
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          top: 4.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [widget.gradColor1, widget.gradColor2],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.elliptical(20.0, 20.0),
                            topRight: Radius.elliptical(20.0, 20.0),
                          ),
                        ),
                        child: Text(
                          widget.confession == null
                              ? '   -'
                              : '#${widget.confession!.confession_no}',
                          style: GoogleFonts.caveat(
                            textStyle: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 238, 238, 238),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.085,
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.borderColor, width: 3.5),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10.0),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.height < 630.0
                            ? 25.0
                            : 40.0,
                        right: 12.0,
                        top: MediaQuery.of(context).size.height < 630.0
                            ? 7.0
                            : 10.0,
                        bottom: 5.0,
                      ),
                      child: Center(
                        child: Text(
                          widget.confession == null
                              ? '-'
                              : '${widget.confession!.confession}',
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.height < 630.0
                                      ? 14.0
                                      : 16.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
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
  }
}
