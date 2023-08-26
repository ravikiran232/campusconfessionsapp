import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_page.dart';
import 'confession_home_page.dart';

class Emailverify extends StatelessWidget {
  const Emailverify({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return MaterialApp(
        theme: ThemeData(),
        home: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(statusBarColor: Colors.blue),
            child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  title: const Center(child: Text("verification")),
                  titleTextStyle: const TextStyle(
                      fontStyle: (FontStyle.italic),
                      fontWeight: FontWeight.w500,
                      fontSize: 40),
                  toolbarHeight: height * 0.35,
                  toolbarOpacity: 0.1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                    bottom: Radius.elliptical(width, 100),
                  )),
                ),
                body: MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          vertical: 30, horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "📩 Almost there! Confirm your registration by tapping the link in your email. Then, head back here and tap Login to complete the process. 🚀",
                            style: GoogleFonts.secularOne(
                              textStyle: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseAuth.instance.currentUser
                                          ?.sendEmailVerification();
                                      Fluttertoast.showToast(msg: "Link sent");
                                    } catch (e) {
                                      Fluttertoast.showToast(
                                          msg:
                                              "something went wrong, try again");
                                    }
                                  },
                                  child: const Text(
                                    "resend",
                                    style: TextStyle(color: Colors.white),
                                  )),
                              ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseAuth.instance.currentUser
                                          ?.reload();
                                      if (FirebaseAuth.instance.currentUser
                                              ?.emailVerified ==
                                          true) {
                                        Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder: ((context) =>
                                                    ConfessionHomePage())));
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: "Email not verified");
                                      }
                                    } catch (e) {
                                      Fluttertoast.showToast(
                                          msg:
                                              "something went wrong, try again");
                                    }
                                  },
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(color: Colors.white),
                                  )),
                              ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: ((context) =>
                                                LoginPage())));
                                  },
                                  child: const Text(
                                    "signout",
                                    style: TextStyle(color: Colors.white),
                                  ))
                            ],
                          ),
                          ElevatedButton(
                              onPressed: () {
                                var url = Uri.parse(
                                    "mailto:teamconfessionsiitk@gmail.com?subject=verification problem(${FirebaseAuth.instance.currentUser?.email})&body=");
                                try {
                                  launchUrl(url);
                                } catch (e) {
                                  Fluttertoast.showToast(msg: e.toString());
                                }
                              },
                              child: const Text("contact us"))
                        ],
                      )),
                ))));
  }
}
