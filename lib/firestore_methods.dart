import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled2/models.dart' as Models;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import "package:encrypt/encrypt.dart" as en;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' as pt;
import 'package:pointycastle/random/fortuna_random.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> postConfessionToAdmin(
      List<dynamic> admins,
      Models.Confession confession,
      Models.User user,
      en.Encrypter secureEncrypter,
      en.Key sharedSecureKey) async {
    String res = 'Some error occurred';
    try {
      await _firestore.collection('waitlist').doc(confession.confessionId).set({
        'approved': false,
        // 'adminEncryptedSharedKey': adminEncryptedSharedKeys,
        'confession': {
          'avatarURL': _auth.currentUser!.photoURL,
          'datePublished': confession.datePublished,
          'views': confession.views,
          'upvotes': confession.upvotes,
          'downvotes': confession.downvotes,
          'reactions': confession.reactions,
          'confession': confession.confession!.trim(),
          'enableAnonymousChat': confession.enableAnonymousChat,
          'user_uid': confession.user_uid, //encrypted
          'confessionId': confession.confessionId,
          'enableSpecificIndividuals': confession.enableSpecificIndividuals,
          'specificIndividuals': confession.specificIndividuals, //encrypted
          'seenBySIs': confession.seenBySIs, //empty
          'chatRoomIDs': confession.chatRoomIDs,
          'enablePoll': confession.enablePoll,
          'poll': confession.poll,
          'encryptedSharedKeys': confession.encryptedSharedKeys, //encrypted
          'notifyCountSIs': 0,
          'adminPost': confession.adminPost
        },
        'user': {
          'uid': secureEncrypter
              .encrypt(user.uid, iv: en.IV.fromBase64('campus12'))
              .base64,
          'avatarURL': _auth.currentUser!.photoURL!,
        }
      });
      res = 'Posted to admin successfully';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> postConfessionFromAdmin(Models.Confession confession) async {
    String res = 'Some error occurred';
    try {
      await _firestore
          .collection('confessions')
          .doc(confession.confessionId)
          .set({
        'avatarURL': confession.avatarURL,
        'datePublished': confession.datePublished,
        'views': confession.views,
        'upvotes': confession.upvotes,
        'downvotes': confession.downvotes,
        'reactions': confession.reactions,
        'confession': confession.confession!.trim(),
        'enableAnonymousChat': confession.enableAnonymousChat,
        'user_uid': confession.user_uid,
        'confession_no': confession.confession_no,
        'confessionId': confession.confessionId,
        'enableSpecificIndividuals': confession.enableSpecificIndividuals,
        'specificIndividuals': confession.specificIndividuals,
        'seenBySIs': confession.seenBySIs,
        'chatRoomIDs': confession.chatRoomIDs,
        'enablePoll': confession.enablePoll,
        'poll': confession.poll,
        'encryptedSharedKeys': confession.encryptedSharedKeys,
        'notifyCountSIs': 0,
        'adminPost': confession.adminPost
      });
      await _firestore.collection('waitlist').doc(confession.confessionId).set({
        'approved': true,
      });
      await _firestore
          .collection('waitlist')
          .doc(confession.confessionId)
          .delete();
      res = 'Confession posted successfully';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> voteOnPoll(
      String confessionId, String option, List<String> optionLabels) async {
    String res = 'Some error occurred';
    Map<String, dynamic> updateMap = {
      'poll.options.1.${optionLabels[0]}': option == '1'
          ? FieldValue.arrayUnion([_auth.currentUser!.uid])
          : FieldValue.arrayRemove([_auth.currentUser!.uid]),
      'poll.options.2.${optionLabels[1]}': option == '2'
          ? FieldValue.arrayUnion([_auth.currentUser!.uid])
          : FieldValue.arrayRemove([_auth.currentUser!.uid]),
    };
    if (optionLabels.length > 2) {
      updateMap['poll.options.3.${optionLabels[2]}'] = option == '3'
          ? FieldValue.arrayUnion([_auth.currentUser!.uid])
          : FieldValue.arrayRemove([_auth.currentUser!.uid]);
    }
    if (optionLabels.length > 3) {
      updateMap['poll.options.4.${optionLabels[3]}'] = option == '4'
          ? FieldValue.arrayUnion([_auth.currentUser!.uid])
          : FieldValue.arrayRemove([_auth.currentUser!.uid]);
    }
    await _firestore
        .collection('confessions')
        .doc(confessionId)
        .update(updateMap);
    res = 'Voted successfully';
    return res;
  }

  Future<String> viewedConfession(
      Models.Confession confession, en.Encrypter? encrypter) async {
    String res = 'Some error occurred';
    try {
      await _firestore
          .collection('confessions')
          .doc(confession.confessionId)
          .update({
        'views': FieldValue.arrayUnion([_auth.currentUser!.uid]),
        'seenBySIs': encrypter == null
            ? FieldValue.arrayUnion([])
            : confession.specificIndividuals.contains(encrypter
                    .encrypt(_auth.currentUser!.email!,
                        iv: en.IV.fromBase64('campus12'))
                    .base64)
                ? FieldValue.arrayUnion([
                    encrypter
                        .encrypt(_auth.currentUser!.email!,
                            iv: en.IV.fromBase64('campus12'))
                        .base64
                  ])
                : FieldValue.arrayUnion([])
      });
      if (!confession.views.contains(_auth.currentUser!.uid) &&
          encrypter != null &&
          confession.specificIndividuals.contains(encrypter
              .encrypt(_auth.currentUser!.email!,
                  iv: en.IV.fromBase64('campus12'))
              .base64)) {
        List tokens = await getTokensFromUids([
          encrypter.decrypt(en.Encrypted.fromBase64(confession.user_uid),
              iv: en.IV.fromBase64('campus12'))
        ]);
        String requiredToken = tokens[0];
        Map<dynamic, dynamic> data = {
          'to': requiredToken,
          'priority': 'high',
          'data': {
            'title': 'Confessions',
            'body': "A specific individual viewed your confession!",
            'type': 'viewedConfession',
            'confession': confession.toJson()
          }
        };
        await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
            body: jsonEncode(data),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization':
                  'key=AAAAtA6V0JA:APA91bEwrE_GBMBe-aWVap09EcR0H9peWaMIY3nM9ewzsxCxjYL9gbBuGPIIPvs-jStFGTMnFI6cq7Lw_bH3yaRuuwymAVppZO1Y6fGI45QgscvFzEfYXHIrn9on6b68y1F59Jg6KweO'
            });
      }
      res = 'successfully updated view.';
    } catch (e) {
      e.toString();
    }
    return res;
  }

  Future<String> actionOnConfession(
      String action_type,
      String confession_id,
      String user_uid,
      DocumentSnapshot<Map<String, dynamic>> confession_snapshot) async {
    String res = 'Some error occurred.';
    if (action_type == 'enable_upvote') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'upvotes': FieldValue.arrayUnion([user_uid])
        });
        res = 'successfully enabled upvote';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'disable_upvote') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'upvotes': FieldValue.arrayRemove([user_uid])
        });
        res = 'successfully disabled upvote';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'enable_downvote') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'downvotes': FieldValue.arrayUnion([user_uid])
        });
        res = 'successfully enabled downvote';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'disable_downvote') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'downvotes': FieldValue.arrayRemove([user_uid])
        });
        res = 'successfully disabled downvote';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'enable_like') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': [...confession_snapshot['reactions']['like'], user_uid],
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully enabled like';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'enable_love') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': [...confession_snapshot['reactions']['love'], user_uid],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully enabled love';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'enable_haha') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': [...confession_snapshot['reactions']['haha'], user_uid],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully enabled haha';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'enable_wink') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': [...confession_snapshot['reactions']['wink'], user_uid],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully enabled wink';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'enable_woah') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': [...confession_snapshot['reactions']['woah'], user_uid],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully enabled woah';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'enable_sad') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': [...confession_snapshot['reactions']['sad'], user_uid],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully enabled sad';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'enable_angry') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': [...confession_snapshot['reactions']['angry'], user_uid],
          }
        });
        res = 'successfully enabled angry';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'disable_like') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': [...confession_snapshot['reactions']['like']]
              ..remove(user_uid),
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully disabled like';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'disable_love') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': [...confession_snapshot['reactions']['love']]
              ..remove(user_uid),
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully disabled love';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'disable_haha') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': [...confession_snapshot['reactions']['haha']]
              ..remove(user_uid),
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully disabled haha';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'disable_wink') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': [...confession_snapshot['reactions']['wink']]
              ..remove(user_uid),
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully disabled wink';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'disable_woah') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': [...confession_snapshot['reactions']['woah']]
              ..remove(user_uid),
            'sad': confession_snapshot['reactions']['sad'],
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully disabled woah';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'disable_sad') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': [...confession_snapshot['reactions']['sad']]
              ..remove(user_uid),
            'angry': confession_snapshot['reactions']['angry'],
          }
        });
        res = 'successfully disabled sad';
      } catch (e) {
        res = e.toString();
      }
    } else if (action_type == 'disable_angry') {
      try {
        await _firestore.collection('confessions').doc(confession_id).update({
          'reactions': {
            'like': confession_snapshot['reactions']['like'],
            'love': confession_snapshot['reactions']['love'],
            'haha': confession_snapshot['reactions']['haha'],
            'wink': confession_snapshot['reactions']['wink'],
            'woah': confession_snapshot['reactions']['woah'],
            'sad': confession_snapshot['reactions']['sad'],
            'angry': [...confession_snapshot['reactions']['angry']]
              ..remove(user_uid),
          }
        });
        res = 'successfully disabled angry';
      } catch (e) {
        res = e.toString();
      }
    }
    return res;
  }

  Future<String> writeComment(
      String confession_id,
      String comment,
      String user_uid,
      String avatarURL,
      String confessionOwner,
      en.Encrypter encrypter) async {
    String res = 'Some error occurred.';
    String comment_id = Uuid().v4();
    try {
      await _firestore
          .collection('confessions')
          .doc(confession_id)
          .collection('comments')
          .doc(comment_id)
          .set({
        'user_uid': encrypter.encrypt(user_uid).base64,
        'commentId': comment_id,
        'confessionId': confession_id,
        'avatarURL': avatarURL,
        'comment': comment,
        'upvotes': [],
        'downvotes': [],
        'reactions': {
          'like': [],
          'love': [],
          'haha': [],
          'wink': [],
          'woah': [],
          'sad': [],
          'angry': [],
        },
        'datePublished': Timestamp.now(),
        'confessionOwner': confessionOwner
      });
      res = 'successfully commented';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> deleteComment(String confession_id, String comment_id) async {
    String res = 'Some error occurred.';
    try {
      await _firestore
          .collection('confessions')
          .doc(confession_id)
          .collection('comments')
          .doc(comment_id)
          .delete();
      res = 'successfully deleted comment';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> actionOnComment(
    String action_type,
    String enable,
    String disable,
    Models.Comment comment,
    String user_uid,
  ) async {
    String res = 'Some error occurred.';
    try {
      if (action_type == 'vote') {
        await _firestore
            .collection('confessions')
            .doc(comment.confessionId!)
            .collection('comments')
            .doc(comment.commentId!)
            .update({
          'upvotes': enable == 'upvote'
              ? FieldValue.arrayUnion([user_uid])
              : disable == 'upvote'
                  ? FieldValue.arrayRemove([user_uid])
                  : FieldValue.arrayUnion([]),
          'downvotes': enable == 'downvote'
              ? FieldValue.arrayUnion([user_uid])
              : disable == 'downvote'
                  ? FieldValue.arrayRemove([user_uid])
                  : FieldValue.arrayUnion([]),
        });
        res = 'successfully ${enable}d';
      } else if (action_type == 'reaction') {
        await _firestore
            .collection('confessions')
            .doc(comment.confessionId!)
            .collection('comments')
            .doc(comment.commentId!)
            .update({
          'reactions': {
            'like': enable == 'like'
                ? [...comment.reactions['like'], user_uid]
                : disable == 'like'
                    ? [
                        ...[...comment.reactions['like']]..remove(user_uid)
                      ]
                    : comment.reactions['like'],
            'love': enable == 'love'
                ? [...comment.reactions['love'], user_uid]
                : disable == 'love'
                    ? [
                        ...[...comment.reactions['love']]..remove(user_uid)
                      ]
                    : comment.reactions['love'],
            'haha': enable == 'haha'
                ? [...comment.reactions['haha'], user_uid]
                : disable == 'haha'
                    ? [
                        ...[...comment.reactions['haha']]..remove(user_uid)
                      ]
                    : comment.reactions['haha'],
            'wink': enable == 'wink'
                ? [...comment.reactions['wink'], user_uid]
                : disable == 'wink'
                    ? [
                        ...[...comment.reactions['wink']]..remove(user_uid)
                      ]
                    : comment.reactions['wink'],
            'woah': enable == 'woah'
                ? [...comment.reactions['woah'], user_uid]
                : disable == 'woah'
                    ? [
                        ...[...comment.reactions['woah']]..remove(user_uid)
                      ]
                    : comment.reactions['woah'],
            'sad': enable == 'sad'
                ? [...comment.reactions['sad'], user_uid]
                : disable == 'sad'
                    ? [
                        ...[...comment.reactions['sad']]..remove(user_uid)
                      ]
                    : comment.reactions['sad'],
            'angry': enable == 'angry'
                ? [...comment.reactions['angry'], user_uid]
                : disable == 'angry'
                    ? [
                        ...[...comment.reactions['angry']]..remove(user_uid)
                      ]
                    : comment.reactions['angry'],
          }
        });
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<List<dynamic>> getTokensFromMails(List<dynamic> mails) async {
    List<dynamic> tokens = [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', whereIn: mails)
          .get();
      List<QueryDocumentSnapshot> specificUserDocs = querySnapshot.docs;
      tokens = specificUserDocs.map((doc) => doc['token']).toList();
    } catch (e) {}
    return tokens;
  }

  Future<List<dynamic>> getTokensFromUids(List<String> Uids) async {
    List<dynamic> tokens = [];
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('uid', whereIn: Uids)
          .get();
      List<QueryDocumentSnapshot> specificUserDocs = querySnapshot.docs;
      tokens = specificUserDocs.map((doc) => doc['token']).toList();
    } catch (e) {}
    return tokens;
  }
}

decodingdata(final data) {
  final map = data as Map;
  List<types.Message> messages = [];
  for (var value in map.values) {
    if (value["status"] == "read") {
      messages.add(types.TextMessage(
          author: types.User(id: value["author"]),
          id: value["id"],
          text: value["text"],
          createdAt: value["createdAt"],
          status: types.Status.seen));
    }
    if (value["status"] == "delivered") {
      messages.add(types.TextMessage(
          author: types.User(id: value["author"]),
          id: value["id"],
          text: value["text"],
          createdAt: value["createdAt"],
          status: types.Status.delivered));
    }
    if (value["status"] == "sent") {
      messages.add(types.TextMessage(
          author: types.User(id: value["author"]),
          id: value["id"],
          text: value["text"],
          createdAt: value["createdAt"],
          status: types.Status.sent));
    }
  }
  return messages;
}
