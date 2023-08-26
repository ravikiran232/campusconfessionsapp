import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:untitled2/firestore_methods.dart';
import 'package:untitled2/single_reaction_widget.dart';
import 'package:untitled2/vote_clipper.dart';
import 'models.dart' as Models;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class CommentClipper extends StatefulWidget {
  en.Encrypter? encrypter;
  RSAPrivateKey privateKey;
  Models.Comment comment;
  bool disableEverything;
  bool isOwner;
  CommentClipper(
      {super.key,
      required this.encrypter,
      required this.privateKey,
      required this.comment,
      required this.isOwner,
      this.disableEverything = false});

  @override
  State<CommentClipper> createState() => _CommentClipperState();
}

class _CommentClipperState extends State<CommentClipper> {
  bool enableCommentreview = false;
  bool upvoteOnHold = false;
  bool downvoteOnHold = false;

  List<double> emojiState = [0, 0, 0, 0, 0, 0, 0];
  double currentHoverposition = 0;
  int currentSelectedEmoji = -1;

  final FirestoreMethods _firestoreMethods = FirestoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Models.Emoji> emojis = [
    Models.Emoji(path: 'assets/emoticons/9420-thumbs-up.json', scale: 1.2),
    Models.Emoji(
        path: 'assets/emoticons/11057-simple-elegant-like-heart-animation.json',
        scale: 1.0),
    Models.Emoji(path: 'assets/emoticons/2093-laugh.json', scale: 1.0),
    Models.Emoji(
        path: 'assets/emoticons/114067-wink-tongue-out-emoji-animation.json',
        scale: 1.3),
    Models.Emoji(path: 'assets/emoticons/2086-wow.json', scale: 1.0),
    Models.Emoji(path: 'assets/emoticons/34175-sad-face.json', scale: 0.85),
    Models.Emoji(path: 'assets/emoticons/51920-angry.json', scale: 1.2),
  ];

  final List<String> reactions = [
    'like',
    'love',
    'haha',
    'wink',
    'woah',
    'sad',
    'angry'
  ];

  final Map<String, SingleReactionWidget> reactionEmojis = {
    'like': SingleReactionWidget(
      label: 'like',
      label_color: Colors.blue,
      emoji_path: 'assets/emoticons/82649-thumbs-up.json',
      lottie: true,
      showLabel: false,
      lottie_scale: 0.7,
    ),
    'love': SingleReactionWidget(
      label: 'love',
      label_color: Colors.red,
      emoji: '❤️',
      showLabel: false,
    ),
    'haha': SingleReactionWidget(
      label: 'haha',
      label_color: Colors.amber,
      emoji: '😆',
      showLabel: false,
    ),
    'wink': SingleReactionWidget(
      label: 'wink',
      label_color: Colors.amber,
      emoji: '😜',
      showLabel: false,
    ),
    'woah': SingleReactionWidget(
      label: 'woah',
      label_color: Colors.amber,
      emoji: '😯',
      showLabel: false,
    ),
    'sad': SingleReactionWidget(
      label: 'sad',
      label_color: Colors.amber,
      emoji: '😔',
      showLabel: false,
    ),
    'angry': SingleReactionWidget(
      label: 'angry',
      label_color: Colors.orange,
      emoji: '😡',
      showLabel: false,
    ),
  };

  String _getReaction(Models.Comment comment) {
    String reaction = 'none';
    if (comment.reactions['like'].contains(_auth.currentUser!.uid)) {
      reaction = 'like';
    } else if (comment.reactions['love'].contains(_auth.currentUser!.uid)) {
      reaction = 'love';
    } else if (comment.reactions['haha'].contains(_auth.currentUser!.uid)) {
      reaction = 'haha';
    } else if (comment.reactions['wink'].contains(_auth.currentUser!.uid)) {
      reaction = 'wink';
    } else if (comment.reactions['woah'].contains(_auth.currentUser!.uid)) {
      reaction = 'woah';
    } else if (comment.reactions['sad'].contains(_auth.currentUser!.uid)) {
      reaction = 'sad';
    } else if (comment.reactions['angry'].contains(_auth.currentUser!.uid)) {
      reaction = 'angry';
    }
    return reaction;
  }

  String _getVote(Models.Comment comment) {
    String vote = 'none';
    if (comment.upvotes.contains(_auth.currentUser!.uid)) {
      vote = 'upvote';
    } else if (comment.downvotes.contains(_auth.currentUser!.uid)) {
      vote = 'downvote';
    }
    return vote;
  }

  void prevEmoji() {
    currentSelectedEmoji > 0
        ? currentSelectedEmoji -= 1
        : currentSelectedEmoji = 0;
    for (int j = 0; j < emojiState.length; j++) {
      if (currentSelectedEmoji != -1) {
        j == currentSelectedEmoji ? emojiState[j] = 0.5 : emojiState[j] = -0.3;
      } else {
        emojiState[j] = 0;
      }
    }
  }

  void nextEmoji() {
    currentSelectedEmoji < emojis.length - 1
        ? currentSelectedEmoji += 1
        : currentSelectedEmoji = emojis.length - 1;
    for (int j = 0; j < emojiState.length; j++) {
      if (currentSelectedEmoji != -1) {
        j == currentSelectedEmoji ? emojiState[j] = 0.5 : emojiState[j] = -0.3;
      } else {
        emojiState[j] = 0;
      }
    }
  }

  void _deleteComment(String confession_id, String comment_id) async {
    String res =
        await _firestoreMethods.deleteComment(confession_id, comment_id);
  }

  void _upvoted(Models.Comment comment) async {
    String prev_vote = _getVote(comment);
    String res = await _firestoreMethods.actionOnComment(
        'vote', 'upvote', prev_vote, comment, _auth.currentUser!.uid);
  }

  void _downvoted(Models.Comment comment) async {
    String prev_vote = _getVote(comment);
    await _firestoreMethods.actionOnComment(
        'vote', 'downvote', prev_vote, comment, _auth.currentUser!.uid);
  }

  void _reacted(int reaction_idx, Models.Comment comment) async {
    if (await checkConnectivity()) {
      String prev_reaction = _getReaction(comment);
      if (prev_reaction != reactions[reaction_idx]) {
        await _firestoreMethods.actionOnComment(
            'reaction',
            reactions[reaction_idx],
            prev_reaction,
            comment,
            _auth.currentUser!.uid);
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Please check your internet connection',
        textColor: Colors.white,
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
      );
    }
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
              width: MediaQuery.of(context).size.width * 0.04,
            ),
            ClipPath(
              clipper: _CommentShape(),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.04,
                height: MediaQuery.of(context).size.height * 0.02,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 242, 242, 242),
                ),
              ),
            ),
          ],
        ),
        InkWell(
          onLongPress: () {
            setState(() {
              enableCommentreview = true;
              widget.disableEverything = false;
            });
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
            padding: const EdgeInsets.only(
                left: 10.0, right: 10.0, top: 5.0, bottom: 3.0),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 242, 242, 242),
              borderRadius: BorderRadius.all(
                Radius.circular(15.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 152, 152, 152),
                  spreadRadius: 0.5,
                  blurRadius: 2.0,
                  offset: Offset(5.0, 4.0),
                )
              ],
            ),
            child: !widget.disableEverything && enableCommentreview
                ? Stack(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 2.0,
                              bottom: 5.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (await checkConnectivity()) {
                                        _upvoted(
                                          widget.comment,
                                        );
                                      } else {
                                        Fluttertoast.showToast(
                                          msg:
                                              'Please check your internet connection',
                                          textColor: Colors.white,
                                          backgroundColor: const Color.fromARGB(
                                              211, 0, 0, 0),
                                        );
                                      }
                                      setState(() {
                                        upvoteOnHold = false;
                                        downvoteOnHold = false;
                                        enableCommentreview = false;
                                      });
                                    },
                                    onLongPressDown: (details) {
                                      setState(
                                        () => upvoteOnHold = true,
                                      );
                                    },
                                    onLongPressUp: () {
                                      upvoteOnHold
                                          ? _upvoted(
                                              widget.comment,
                                            )
                                          : null;
                                      setState(() {
                                        upvoteOnHold = false;
                                        downvoteOnHold = false;
                                        enableCommentreview = false;
                                      });
                                    },
                                    onLongPressMoveUpdate: (details) {
                                      if (details.localPosition.dx.abs() > 50) {
                                        setState(
                                          () => upvoteOnHold = false,
                                        );
                                      }
                                    },
                                    child: AnimatedScale(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      scale: upvoteOnHold ? 1.5 : 1.1,
                                      child: VoteClipper(
                                        color: Colors.green,
                                        icon_height: 20.0,
                                        icon_width: 20.0,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (await checkConnectivity()) {
                                        _downvoted(
                                          widget.comment,
                                        );
                                      } else {
                                        Fluttertoast.showToast(
                                          msg:
                                              'Please check your internet connection',
                                          textColor: Colors.white,
                                          backgroundColor: const Color.fromARGB(
                                              211, 0, 0, 0),
                                        );
                                      }
                                      setState(() {
                                        downvoteOnHold = false;
                                        upvoteOnHold = false;
                                        enableCommentreview = false;
                                      });
                                    },
                                    onLongPressDown: (details) {
                                      setState(
                                        () => downvoteOnHold = true,
                                      );
                                    },
                                    onLongPressUp: () {
                                      downvoteOnHold
                                          ? _downvoted(
                                              widget.comment,
                                            )
                                          : null;
                                      setState(() {
                                        downvoteOnHold = false;
                                        upvoteOnHold = false;
                                        enableCommentreview = false;
                                      });
                                    },
                                    onLongPressMoveUpdate: (details) {
                                      if (details.localPosition.dx.abs() > 50) {
                                        setState(
                                          () => downvoteOnHold = false,
                                        );
                                      }
                                    },
                                    child: AnimatedScale(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      scale: downvoteOnHold ? 1.5 : 1.1,
                                      child: Transform.rotate(
                                        angle: 1.5707963267948966 * 2,
                                        child: VoteClipper(
                                          color: Colors.red,
                                          icon_height: 20.0,
                                          icon_width: 20.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.contain,
                            child: Container(
                              //width: MediaQuery.of(context).size.width,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                                color: Color.fromARGB(197, 242, 242, 242),
                              ),
                              margin:
                                  const EdgeInsets.only(top: 10.0, bottom: 5.0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 3.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (int i = 0; i < emojis.length; i++)
                                    GestureDetector(
                                      onTap: () {
                                        _reacted(
                                          i,
                                          widget.comment,
                                        );
                                        setState(
                                          () {
                                            emojiState = [0, 0, 0, 0, 0, 0, 0];
                                            enableCommentreview = false;
                                          },
                                        );
                                      },
                                      onLongPressDown: (details) {
                                        setState(() {
                                          for (int j = 0;
                                              j < emojiState.length;
                                              j++) {
                                            j == i
                                                ? emojiState[j] = 0.5
                                                : emojiState[j] = -0.3;
                                          }
                                          currentSelectedEmoji = i;
                                        });
                                        currentHoverposition =
                                            details.localPosition.dx;
                                      },
                                      onLongPressMoveUpdate: (details) {
                                        double dragDifference =
                                            details.localPosition.dx -
                                                currentHoverposition;
                                        if (dragDifference.abs() >
                                            MediaQuery.of(context).size.width *
                                                0.11) {
                                          if (dragDifference > 0) {
                                            setState(() {
                                              nextEmoji();
                                            });
                                          } else {
                                            setState(() {
                                              prevEmoji();
                                            });
                                          }
                                          currentHoverposition =
                                              details.localPosition.dx;
                                        }
                                      },
                                      onLongPressUp: () {
                                        _reacted(
                                          currentSelectedEmoji,
                                          widget.comment,
                                        );
                                        setState(
                                          () {
                                            emojiState = [0, 0, 0, 0, 0, 0, 0];
                                            enableCommentreview = false;
                                          },
                                        );
                                      },
                                      child: AnimatedScale(
                                        scale: emojiState[i] == 0
                                            ? 1.0
                                            : 1.0 + emojiState[i],
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Transform.scale(
                                          scale: emojis[i].scale,
                                          child: Lottie.asset(
                                            emojis[i].path,
                                            height: 50.0,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => enableCommentreview = false),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 18.0,
                          ),
                        ),
                      ),
                      widget.isOwner ||
                              (widget.encrypter != null &&
                                  widget.encrypter
                                          ?.encrypt(
                                              //here is the error
                                              _auth.currentUser!.uid,
                                              iv: en.IV.fromBase64('campus12'))
                                          .base64 ==
                                      widget.comment.confessionOwner)
                          ? Positioned(
                              right: 0.0,
                              child: GestureDetector(
                                onTap: () async {
                                  if (await checkConnectivity()) {
                                    _deleteComment(widget.comment.confessionId!,
                                        widget.comment.commentId!);
                                  } else {
                                    Fluttertoast.showToast(
                                      msg:
                                          'Please check your internet connection',
                                      textColor: Colors.white,
                                      backgroundColor:
                                          const Color.fromARGB(211, 0, 0, 0),
                                    );
                                  }
                                  setState(() {
                                    enableCommentreview = false;
                                  });
                                },
                                child: const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 5.0),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 18.0,
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          widget.isOwner
                              ? const Text(
                                  'My comment:',
                                  style: TextStyle(
                                      fontSize: 13.0,
                                      color: Color.fromARGB(255, 0, 154, 225),
                                      fontWeight: FontWeight.bold),
                                )
                              : Container(),
                          Flexible(child: Container()),
                          Text(
                            DateFormat.yMd().format(
                              widget.comment.datePublished!.toDate(),
                            ),
                            style: const TextStyle(
                                color: Color.fromARGB(255, 90, 90, 90),
                                fontSize: 8.0),
                          ),
                        ],
                      ),
                      Text(
                        widget.comment.comment!,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 5.0,
                            left: 5.0,
                            right: 2.0,
                            bottom: (widget.comment.upvotes.isNotEmpty ||
                                    widget.comment.downvotes.isNotEmpty ||
                                    (widget.comment.reactions['like'].length +
                                            widget.comment.reactions['love']
                                                .length +
                                            widget.comment.reactions['haha']
                                                .length +
                                            widget.comment.reactions['wink']
                                                .length +
                                            widget.comment.reactions['woah']
                                                .length +
                                            widget.comment.reactions['sad']
                                                .length +
                                            widget.comment.reactions['angry']
                                                .length) >
                                        0)
                                ? 0.0
                                : 5.0),
                        child: Row(
                          children: [
                            (widget.comment.upvotes.isNotEmpty ||
                                    widget.comment.downvotes.isNotEmpty)
                                ? Text(
                                    '${widget.comment.upvotes.length}',
                                    style: GoogleFonts.secularOne(
                                        textStyle: TextStyle(
                                            color: widget.comment.upvotes
                                                    .contains(
                                                        _auth.currentUser!.uid)
                                                ? Colors.green
                                                : Colors.black)),
                                  )
                                : Container(),
                            (widget.comment.upvotes.isNotEmpty ||
                                    widget.comment.downvotes.isNotEmpty)
                                ? Transform.scale(
                                    scale: 0.6,
                                    child: VoteClipper(
                                      color: Colors.green,
                                      icon_height: 20.0,
                                      icon_width: 20.0,
                                    ),
                                  )
                                : Container(),
                            const SizedBox(
                              width: 5.0,
                            ),
                            (widget.comment.upvotes.isNotEmpty ||
                                    widget.comment.downvotes.isNotEmpty)
                                ? Text(
                                    '${widget.comment.downvotes.length}',
                                    style: GoogleFonts.secularOne(
                                        textStyle: TextStyle(
                                            color: widget.comment.downvotes
                                                    .contains(
                                                        _auth.currentUser!.uid)
                                                ? Colors.red
                                                : Colors.black)),
                                  )
                                : Container(),
                            (widget.comment.upvotes.isNotEmpty ||
                                    widget.comment.downvotes.isNotEmpty)
                                ? Transform.scale(
                                    scale: 0.6,
                                    child: Transform.rotate(
                                      angle: 1.5707963267948966 * 2,
                                      child: VoteClipper(
                                        color: Colors.red,
                                        icon_height: 20.0,
                                        icon_width: 20.0,
                                      ),
                                    ),
                                  )
                                : Container(),
                            Flexible(child: Container()),
                            _getReaction(widget.comment) == 'none'
                                ? Container()
                                : reactionEmojis[
                                    _getReaction(widget.comment)]!, //befuc
                            (widget.comment.reactions['like'].length +
                                        widget
                                            .comment.reactions['love'].length +
                                        widget
                                            .comment.reactions['haha'].length +
                                        widget
                                            .comment.reactions['wink'].length +
                                        widget
                                            .comment.reactions['woah'].length +
                                        widget.comment.reactions['sad'].length +
                                        widget.comment.reactions['angry']
                                            .length) >
                                    0
                                ? InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return MediaQuery(
                                            data: MediaQuery.of(context)
                                                .copyWith(textScaleFactor: 1.0),
                                            child: SimpleDialog(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0)),
                                              titlePadding:
                                                  const EdgeInsets.only(
                                                      top: 10.0, left: 10.0),
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                      bottom: 10.0, top: 3.0),
                                              title: Text(
                                                'Reactions: ${widget.comment.reactions['like'].length + widget.comment.reactions['love'].length + widget.comment.reactions['haha'].length + widget.comment.reactions['wink'].length + widget.comment.reactions['woah'].length + widget.comment.reactions['sad'].length + widget.comment.reactions['angry'].length}',
                                                style: GoogleFonts.secularOne(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w100,
                                                  color: const Color.fromARGB(
                                                      255, 61, 61, 61),
                                                ),
                                              ),
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    widget
                                                                .comment
                                                                .reactions[
                                                                    'like']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              SingleReactionWidget(
                                                                label: '',
                                                                emoji_path:
                                                                    'assets/emoticons/82649-thumbs-up.json',
                                                                lottie: true,
                                                                showLabel:
                                                                    false,
                                                              ),
                                                              Text(
                                                                ': ${widget.comment.reactions['like'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    const SizedBox(
                                                      width: 5.0,
                                                    ),
                                                    widget
                                                                .comment
                                                                .reactions[
                                                                    'love']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '❤️',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${widget.comment.reactions['love'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    const SizedBox(
                                                      width: 5.0,
                                                    ),
                                                    widget
                                                                .comment
                                                                .reactions[
                                                                    'haha']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😆',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${widget.comment.reactions['haha'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    const SizedBox(
                                                      width: 5.0,
                                                    ),
                                                    widget
                                                                .comment
                                                                .reactions[
                                                                    'wink']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😜',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${widget.comment.reactions['wink'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 5.0,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    widget
                                                                .comment
                                                                .reactions[
                                                                    'woah']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😯',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${widget.comment.reactions['woah'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    const SizedBox(
                                                      width: 5.0,
                                                    ),
                                                    widget
                                                                .comment
                                                                .reactions[
                                                                    'sad']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😔',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${widget.comment.reactions['sad'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                    const SizedBox(
                                                      width: 5.0,
                                                    ),
                                                    widget
                                                                .comment
                                                                .reactions[
                                                                    'angry']
                                                                .length !=
                                                            0
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                '😡',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18.0),
                                                              ),
                                                              Text(
                                                                ': ${widget.comment.reactions['angry'].length}',
                                                                style: GoogleFonts
                                                                    .secularOne(
                                                                  fontSize:
                                                                      18.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      255,
                                                                      61,
                                                                      61,
                                                                      61),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.015,
                                                              ),
                                                            ],
                                                          )
                                                        : Container(),
                                                  ],
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Text(
                                      '${widget.comment.reactions['like'].length + widget.comment.reactions['love'].length + widget.comment.reactions['haha'].length + widget.comment.reactions['wink'].length + widget.comment.reactions['woah'].length + widget.comment.reactions['sad'].length + widget.comment.reactions['angry'].length} Reactions',
                                      style: GoogleFonts.secularOne(
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _CommentShape extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height * 0.5);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }
}
