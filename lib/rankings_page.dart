import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:untitled2/rankCardIII.dart';

class RankingsPage extends StatefulWidget {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  List rankedConfessions;
  RankingsPage(
      {super.key,
      required this.publicKey,
      required this.privateKey,
      required this.rankedConfessions});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        appBar: AppBar(
          elevation: 5.0,
          titleSpacing: 0.0,
          leading: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.lightBlue, Colors.lightBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)),
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
              gradient: LinearGradient(
                  colors: [Colors.lightBlue, Color.fromARGB(255, 26, 123, 203)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
            ),
            child: Row(
              children: [
                Text(
                  'Rankings',
                  style: GoogleFonts.secularOne(
                    textStyle: const TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 249, 249, 249),
                        letterSpacing: 0.5),
                  ),
                ),
                Flexible(child: Container()),
                const Padding(
                  padding: EdgeInsets.only(right: 10.0),
                  child: Text(
                    'last 14 days',
                    style: TextStyle(
                      fontSize: 15.0,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        body: widget.rankedConfessions.isEmpty
            ? const Center(
                child: Text('No confessions in the last 30 days.'),
              )
            : ListView.builder(
                itemCount: widget.rankedConfessions.length,
                itemBuilder: (context, index) {
                  return RankCardIII(
                    publicKey: widget.publicKey,
                    privateKey: widget.privateKey,
                    confession: widget.rankedConfessions[index],
                    rank: index + 1,
                  );
                },
              ),
      ),
    );
  }
}
