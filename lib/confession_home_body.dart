import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:shimmer/shimmer.dart';
import 'package:untitled2/AdminPage.dart';
import 'package:untitled2/confession_cardII.dart';
import 'package:untitled2/new_confession_page.dart';
import 'package:untitled2/rank_card_II.dart';
import 'package:untitled2/rankings_page.dart';
import 'package:untitled2/models.dart' as Models;
import 'package:untitled2/share_services.dart';

class ConfessionHomeBody extends StatefulWidget {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  List<dynamic> admins;
  String primaryAdmin;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> confessions;
  QuerySnapshot<Map<String, dynamic>>? lastMonthConfessionSnapshot;
  Future<void> Function() handleRefresh;
  void Function() getMoreConfessionData;
  bool hasMoreData;
  ConfessionHomeBody({
    super.key,
    required this.publicKey,
    required this.privateKey,
    required this.admins,
    required this.primaryAdmin,
    required this.confessions,
    required this.handleRefresh,
    required this.getMoreConfessionData,
    required this.hasMoreData,
    required this.lastMonthConfessionSnapshot,
  });

  @override
  State<ConfessionHomeBody> createState() => _ConfessionHomeBodyState();
}

class _ConfessionHomeBodyState extends State<ConfessionHomeBody> {
  bool closeRankContainer = false;
  bool _throughInkWell = false;
  final ScrollController _scrollController = ScrollController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // List<Models.Confession> confessionModelList = [];

  List rankedConfessions = [];

  @override
  void initState() {
    super.initState();
    rankedConfessions = rankConfessions();
    ShareServices()
        .initDynamicLink(context, widget.publicKey, widget.privateKey);
    ShareServices()
        .handleDynamicLink(context, widget.publicKey, widget.privateKey);
    // widget.confessions.map((e) => confessionModelList.add(Models.Confession(enablePoll: false, poll: null, notifyCountSIs: 0, adminPost: false).toConfessionModel(e)))
    _scrollController.addListener(() {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      double delta = MediaQuery.of(context).size.height * 0.25;
      if (maxScroll - currentScroll == 0.0 && widget.hasMoreData) {
        widget.getMoreConfessionData();
      }
      setState(() {
        if (!_throughInkWell) {
          closeRankContainer = _scrollController.offset > 70;
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  List<dynamic> rankConfessions() {
    if (widget.lastMonthConfessionSnapshot == null) {
      return [];
    }
    List sortedConfessions = widget.lastMonthConfessionSnapshot!.docs
        .map((e) => Models.Confession(
                enablePoll: false,
                poll: null,
                notifyCountSIs: 0,
                adminPost: false)
            .toConfessionModel(e))
        .toList();
    sortedConfessions.removeWhere((e) => e.adminPost == true);
    sortedConfessions.sort((a, b) => (0.4 * b.views.length +
            0.3 * b.upvotes.length -
            0.3 * b.downvotes.length)
        .compareTo(0.3 * a.views.length +
            0.35 * a.upvotes.length -
            0.35 * a.downvotes.length));
    return sortedConfessions;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.lightBlue,
                  Color.fromARGB(255, 26, 124, 205)
                ], begin: Alignment.centerLeft, end: Alignment.centerRight),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10.0)
                  .copyWith(top: 5.0, bottom: 0.0),
              child: Row(
                children: [
                  InkWell(
                      onTap: () => setState(() {
                            closeRankContainer = !closeRankContainer;
                            closeRankContainer
                                ? _throughInkWell = true
                                : _throughInkWell = false;
                          }),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Top 3 confessions',
                            style: GoogleFonts.secularOne(
                              textStyle: const TextStyle(
                                  fontSize: 21.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3.0),
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 400),
                              turns: closeRankContainer ? 0.5 : 0,
                              child: Transform.scale(
                                scaleX: 1.0,
                                child: const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.white,
                                  size: 18.0,
                                  shadows: [
                                    Shadow(color: Colors.white, blurRadius: 2.0)
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      )),
                  Flexible(child: Container()),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => RankingsPage(
                            publicKey: widget.publicKey,
                            privateKey: widget.privateKey,
                            rankedConfessions: rankedConfessions),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Rankings',
                          style: TextStyle(
                            color: Color.fromARGB(255, 249, 249, 249),
                            fontWeight: FontWeight.w500,
                            fontSize: 15.0,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Color.fromARGB(255, 249, 249, 249),
                          size: 14.0,
                          shadows: [
                            Shadow(color: Colors.white, blurRadius: 2.0)
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: closeRankContainer ? 0 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.lightBlue,
                    Color.fromARGB(255, 2, 98, 177),
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                        offset: Offset(0.0, 5.0),
                        blurRadius: 2.0,
                        spreadRadius: 0.1,
                        color: Colors.grey)
                  ],
                ),
                width: double.infinity,
                height: closeRankContainer
                    ? 0
                    : MediaQuery.of(context).size.height * 0.37,
                child: FittedBox(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 5.0),
                        child: RankCardII(
                          publicKey: widget.publicKey,
                          privateKey: widget.privateKey,
                          confession: rankedConfessions.isNotEmpty
                              ? rankedConfessions[0]
                              : null,
                          asset_path: 'assets/images/gold_medal.png',
                          borderColor: const Color.fromARGB(215, 222, 173, 24),
                          gradColor1: const Color.fromARGB(255, 255, 203, 49),
                          gradColor2: const Color.fromARGB(255, 143, 109, 9),
                          rank: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 13.0),
                        child: RankCardII(
                          publicKey: widget.publicKey,
                          privateKey: widget.privateKey,
                          confession: rankedConfessions.length > 1
                              ? rankedConfessions[1]
                              : null,
                          asset_path: 'assets/images/silver_medal.png',
                          borderColor: const Color.fromARGB(234, 158, 158, 158),
                          gradColor1: const Color.fromARGB(255, 204, 204, 204),
                          gradColor2: const Color.fromARGB(255, 99, 99, 99),
                          rank: 2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 10.0),
                        child: RankCardII(
                          publicKey: widget.publicKey,
                          privateKey: widget.privateKey,
                          confession: rankedConfessions.length > 2
                              ? rankedConfessions[2]
                              : null,
                          asset_path: 'assets/images/bronze_medal.png',
                          borderColor: const Color.fromARGB(222, 181, 123, 41),
                          gradColor1: const Color.fromARGB(255, 253, 167, 46),
                          gradColor2: const Color.fromARGB(255, 126, 83, 22),
                          rank: 3,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            closeRankContainer
                ? const SizedBox(
                    height: 0.0,
                  )
                : const SizedBox(
                    height: 10.0,
                  ),
            Expanded(
              child: widget.confessions.isNotEmpty
                  ? RefreshIndicator(
                      onRefresh: widget.handleRefresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scrollController,
                        itemCount: widget.confessions.length +
                            (widget.hasMoreData ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == widget.confessions.length) {
                            if (widget.confessions.length +
                                    (widget.hasMoreData ? 1 : 0) >
                                6) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else {
                              return Container();
                            }
                          }
                          return ConfessionCardII(
                            publicKey: widget.publicKey,
                            privateKey: widget.privateKey,
                            showNewCard: widget.confessions[index]['views']
                                    .contains(_auth.currentUser!.uid)
                                ? false
                                : true,
                            confessions: widget.confessions,
                            currentIndex: index,
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text('No confessions to show here'),
                    ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 17.0,
              ),
              child: FloatingActionButton(
                heroTag: 'fab1',
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => NewConfessionPage(
                        publicKey: widget.publicKey,
                        privateKey: widget.privateKey,
                        admins: widget.admins,
                        confessionNum: 0),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 32.0,
                ),
              ),
            ),
            widget.admins.contains(_auth.currentUser!.uid)
                ? Padding(
                    padding: const EdgeInsets.only(
                        right: 10.0, bottom: 17.0, top: 17.0),
                    child: FloatingActionButton(
                      heroTag: 'fab2',
                      backgroundColor: const Color.fromARGB(255, 236, 178, 6),
                      onPressed: () => Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => AdminPage(
                            publicKey: widget.publicKey!,
                            privateKey: widget.privateKey!,
                            admins: widget.admins,
                            primaryAdmin: widget.primaryAdmin,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 32.0,
                      ),
                    ),
                  )
                : Container(),
          ],
        )
      ],
    );
  }
}
