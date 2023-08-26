import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Confession {
  String? confessionId;
  String user_uid;
  String avatarURL;
  int confession_no;
  String? confession;
  bool enableAnonymousChat;
  bool enableSpecificIndividuals;
  List views;
  List upvotes;
  List downvotes;
  Map<String, dynamic> reactions;
  Map<String, dynamic> chatRoomIDs;
  Timestamp? datePublished;
  List<dynamic> specificIndividuals;
  List<dynamic> seenBySIs;
  bool enablePoll;
  Map<String, dynamic>? poll;
  List<dynamic>? encryptedSharedKeys;
  int notifyCountSIs;
  bool adminPost;

  Confession(
      {this.user_uid = 'not current user',
      this.confessionId,
      this.confession,
      this.avatarURL = '',
      this.enableAnonymousChat = false,
      this.enableSpecificIndividuals = false,
      this.specificIndividuals = const [],
      this.seenBySIs = const [],
      this.views = const [],
      this.upvotes = const [],
      this.downvotes = const [],
      this.reactions = const <String, dynamic>{
        'like': [],
        'love': [],
        'haha': [],
        'wink': [],
        'woah': [],
        'sad': [],
        'angry': []
      },
      this.chatRoomIDs = const <String, dynamic>{},
      this.confession_no = -1,
      this.datePublished,
      required this.enablePoll,
      required this.poll,
      this.encryptedSharedKeys,
      required this.notifyCountSIs,
      required this.adminPost});

  Confession toConfessionModel(DocumentSnapshot snapshot) {
    return Confession(
        user_uid: snapshot['user_uid'],
        avatarURL: snapshot['avatarURL'],
        confessionId: snapshot['confessionId'],
        confession: snapshot['confession'],
        enableAnonymousChat: snapshot['enableAnonymousChat'],
        enableSpecificIndividuals: snapshot['enableSpecificIndividuals'],
        views: snapshot['views'],
        upvotes: snapshot['upvotes'],
        downvotes: snapshot['downvotes'],
        reactions: snapshot['reactions'],
        confession_no: snapshot['confession_no'],
        datePublished: snapshot['datePublished'],
        specificIndividuals: snapshot['specificIndividuals'],
        chatRoomIDs: snapshot['chatRoomIDs'],
        enablePoll: snapshot['enablePoll'],
        poll: snapshot['poll'],
        encryptedSharedKeys: snapshot['encryptedSharedKeys'],
        notifyCountSIs: snapshot['notifyCountSIs'],
        adminPost: snapshot['adminPost']);
  }

  String toJson() => jsonEncode(toMap());

  Map<String, dynamic> toMap() {
    return {
      'user_uid': user_uid,
      'confessionId': confessionId,
      'confession': confession,
      'avatarURL': avatarURL,
      'enableAnonymousChat': enableAnonymousChat,
      'enableSpecificIndividuals': enableSpecificIndividuals,
      'specificIndividuals': specificIndividuals,
      'seenBySIs': seenBySIs,
      'views': views,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'reactions': reactions,
      'confession_no': confession_no,
      'datePublished': datePublished!.toDate().toIso8601String(),
      'chatRoomIDs': chatRoomIDs,
      'enablePoll': enablePoll,
      'poll': poll,
      'encryptedSharedKeys': encryptedSharedKeys,
      'notifyCountSIs': notifyCountSIs,
      'adminPost': adminPost
    };
  }
}

class User {
  String uid;
  String avatarURL;
  String email;
  String token;

  User(
      {required this.uid,
      this.avatarURL = 'default',
      required this.email,
      required this.token});
}

class Emoji {
  final String path;
  final double scale;

  Emoji({required this.path, required this.scale});
}

class Comment {
  String? confessionId;
  String? commentId;
  String? comment;
  String? user_uid;
  String? avatarURL;
  List upvotes;
  List downvotes;
  Map<String, dynamic> reactions;
  Timestamp? datePublished;
  String? confessionOwner;

  Comment({
    this.confessionId,
    this.commentId,
    this.comment,
    this.user_uid,
    this.avatarURL,
    this.upvotes = const [],
    this.downvotes = const [],
    this.reactions = const {
      'like': [],
      'love': [],
      'haha': [],
      'wink': [],
      'woah': [],
      'sad': [],
      'angry': [],
    },
    this.datePublished,
    this.confessionOwner,
  });

  Comment toCommentModel(QueryDocumentSnapshot snapshot) {
    return Comment(
      commentId: snapshot['commentId'],
      confessionId: snapshot['confessionId'],
      comment: snapshot['comment'],
      user_uid: snapshot['user_uid'],
      avatarURL: snapshot['avatarURL'],
      datePublished: snapshot['datePublished'],
      upvotes: snapshot['upvotes'],
      downvotes: snapshot['downvotes'],
      reactions: snapshot['reactions'],
      confessionOwner: snapshot['confessionOwner'],
    );
  }
}
