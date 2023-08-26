import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class FrontLoadingPage extends StatefulWidget {
  const FrontLoadingPage({super.key});

  @override
  State<FrontLoadingPage> createState() => _FrontLoadingPageState();
}

class _FrontLoadingPageState extends State<FrontLoadingPage> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 4, 151, 219),
              ),
            ),
          ),
          Shimmer.fromColors(
            baseColor: const Color.fromARGB(255, 25, 125, 207),
            highlightColor: const Color.fromARGB(255, 51, 175, 232),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.0),
              child: Text(
                'Your anonymity is our utmost priority.',
                style: GoogleFonts.secularOne(
                  textStyle: const TextStyle(
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
          ),
          Shimmer.fromColors(
            baseColor: const Color.fromARGB(255, 25, 125, 207),
            highlightColor: const Color.fromARGB(255, 51, 175, 232),
            child: Text(
              'Everyting is end-to-end encrypted.',
              style: GoogleFonts.secularOne(
                textStyle: const TextStyle(
                  fontSize: 15.0,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
