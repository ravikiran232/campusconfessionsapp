import 'dart:convert';
import "package:firebase_auth/firebase_auth.dart";
import 'package:flutter/cupertino.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

loadingmessages(String id) async {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  List<types.Message> messages = [];
  var databasepath = await getDatabasesPath();
  String path = join(databasepath, 'buymessages.db');
  // deleteDatabase(path);
  String path2 = join(databasepath, "unreadmessages.db");
  Database database =
      await openDatabase(path, onCreate: (Database db, int number) async {
    await db
        .execute("Create Table chatmessages (id STRING, messageslist JSON)");
  }, version: 1);
  Database database1 =
      await openDatabase(path2, onCreate: (Database db, int number) async {
    await db.execute(
        "Create Table unread (messageid STRING, createdAt BIGINT, text STRING)");
  }, version: 1);
  List chatmessages = await database
      .rawQuery("SELECT messageslist from chatmessages WHERE id= ?", [id]);

  if (chatmessages.isNotEmpty) {
    for (int i = 0;
        i < jsonDecode(chatmessages[0]["messageslist"]).length;
        i++) {
      if (jsonDecode(chatmessages[0]["messageslist"])[i]["author"]["id"] ==
          uid) {
        if (jsonDecode(chatmessages[0]["messageslist"])[i]["status"] ==
            "sent") {
          messages.add(types.TextMessage(
              createdAt: jsonDecode(chatmessages[0]["messageslist"])[i]
                  ["createdAt"],
              author: types.User(
                  id: jsonDecode(chatmessages[0]["messageslist"])[i]["author"]
                      ["id"]),
              text: jsonDecode(chatmessages[0]["messageslist"])[i]["text"],
              id: jsonDecode(chatmessages[0]["messageslist"])[i]["id"],
              status: types.Status.sent));
        }
        if (jsonDecode(chatmessages[0]["messageslist"])[i]["status"] ==
            "delivered") {
          messages.add(types.TextMessage(
              createdAt: jsonDecode(chatmessages[0]["messageslist"])[i]
                  ["createdAt"],
              author: types.User(
                  id: jsonDecode(chatmessages[0]["messageslist"])[i]["author"]
                      ["id"]),
              text: jsonDecode(chatmessages[0]["messageslist"])[i]["text"],
              id: jsonDecode(chatmessages[0]["messageslist"])[i]["id"],
              status: types.Status.delivered));
        }
        if (jsonDecode(chatmessages[0]["messageslist"])[i]["status"] ==
            "seen") {
          messages.add(types.TextMessage(
              createdAt: jsonDecode(chatmessages[0]["messageslist"])[i]
                  ["createdAt"],
              author: types.User(
                  id: jsonDecode(chatmessages[0]["messageslist"])[i]["author"]
                      ["id"]),
              text: jsonDecode(chatmessages[0]["messageslist"])[i]["text"],
              id: jsonDecode(chatmessages[0]["messageslist"])[i]["id"],
              status: types.Status.seen));
        }
      } else {
        messages.add(types.TextMessage(
          createdAt: jsonDecode(chatmessages[0]["messageslist"])[i]
              ["createdAt"],
          author: types.User(
              id: jsonDecode(chatmessages[0]["messageslist"])[i]["author"]
                  ["id"]),
          text: jsonDecode(chatmessages[0]["messageslist"])[i]["text"],
          id: jsonDecode(chatmessages[0]["messageslist"])[i]["id"],
        ));
      }
      // List unreadmessages =await database1.rawQuery("SELECT * FROM unread ORDER BY createdAt") ;
      // if (unreadmessages.isNotEmpty){
      //   for (int i=0 ; i<unreadmessages.length;i++){
      //     messages.insert(0,TextMessage(author: User(id:"developer"), id: unreadmessages[i]["messageid"], text: unreadmessages[i]["text"],createdAt: unreadmessages[i]["createdAt"]));
      //   }
      // }
    }
  }

  return messages;
}

updatingmessages(messages, String id) async {
  var databasepath = await getDatabasesPath();
  String path = join(databasepath, 'buymessages.db');
  Database database = await openDatabase(path);
  List count_list = await database
      .rawQuery("Select messageslist from chatmessages where id=?", [id]);
  if (count_list.isNotEmpty) {
    database.rawUpdate(
        "Update chatmessages SET messageslist=? where id=?", [messages, id]);
  } else {
    database.rawInsert("Insert into chatmessages(id,messageslist) values(?,?)",
        [id, messages]);
  }
}
