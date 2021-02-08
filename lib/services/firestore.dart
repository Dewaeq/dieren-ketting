import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dieren_ketting/model/user_model.dart';
import 'package:flutter/cupertino.dart';

class StoreMethods {
  Random random = new Random();

  Future<bool> checkForDocument(String collection, String docId) async {
    final doc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .get();
    return doc.exists && doc != null;
  }

  Future<bool> joinGame(String pin, String userName, String uid) async {
    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(pin)
        .collection("members")
        .doc(uid)
        .set({
      "userName": userName,
      "uid": uid,
      "alive": "TRUE",
    });
    return true;
  }

  Future<bool> submitWord({
    @required String word,
    @required String pin,
    @required UserModel currentUser,
    @required UserModel nextUser,
  }) async {
    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(pin)
        .collection("words")
        .add({
      "word": word,
      "time": DateTime.now().millisecondsSinceEpoch.toString(),
      "answerer": currentUser.uid,
    });
    await FirebaseFirestore.instance.collection("rooms").doc(pin).update({
      "currentWord": word,
      "currentPlayer": nextUser.uid,
    });
    return true;
  }

  Future<bool> dontKnowAnswer({
    @required String pin,
    @required UserModel currentUser,
    @required UserModel nextUser,
  }) async {
    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(pin)
        .collection("members")
        .doc(currentUser.uid)
        .update({
      "alive": "FALSE",
    });
    await FirebaseFirestore.instance.collection("rooms").doc(pin).update({
      "currentPlayer": nextUser.uid,
    });
    return true;
  }

  Future<bool> setCurrentPlayer(UserModel newCurrentPlayer, String pin) async {
    await FirebaseFirestore.instance.collection("rooms").doc(pin).update({
      "currentPlayer": newCurrentPlayer.uid,
    });
    return true;
  }

  Future<String> createGame() async {
    String pin = "";
    for (int i = 0; i < 6; i++) {
      int t = random.nextInt(10);
      pin += t.toString();
    }
    assert(pin.length == 6);
    bool exists = await checkForDocument("rooms", pin);
    if (exists) {
      return await createGame();
    }
    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(pin.toString())
        .set({
      "currentPlayer": "NONE",
      "currentWord": "NONE",
      "started": "FALSE",
      "winner": "NONE",
      "order": "NONE",
      "checkWords": "FALSE",
    });
    return pin.toString();
  }

  Future<bool> startGame(String pin, List<String> order) async {
    await FirebaseFirestore.instance.collection("rooms").doc(pin).update({
      "currentPlayer": order[0],
      "started": "TRUE",
      "order": order.join('|'),
    });
    return true;
  }

  Future<bool> restartGame(String pin, List<UserModel> users) async {
    await FirebaseFirestore.instance.collection("rooms").doc(pin).update({
      "currentWord": "NONE",
      "currentPlayer": "NONE",
      "winner": "NONE",
      "started": "FALSE",
    });

    for (var user in users) {
      if (!user.alive) {
        await FirebaseFirestore.instance
            .collection("rooms")
            .doc(pin)
            .collection("members")
            .doc(user.uid)
            .update({
          "alive": "TRUE",
        });
      }
    }

    var words = await FirebaseFirestore.instance
        .collection("rooms")
        .doc(pin)
        .collection("words")
        .get();
    for (var word in words.docs) {
      await word.reference.delete();
    }

    return true;
  }

  Future<bool> kickUser(String pin, UserModel toKick) async {
    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(pin)
        .collection("members")
        .doc(toKick.uid)
        .delete();
    return true;
  }

  Future<bool> setWinner(String pin, UserModel winner) async {
    await FirebaseFirestore.instance.collection("rooms").doc(pin).update({
      "winner": winner.uid,
    });
    return true;
  }

  Future<bool> setCheckWords(String pin, bool checkWords) async {
    await FirebaseFirestore.instance.collection("rooms").doc(pin).update({
      "checkWords": checkWords ? "TRUE" : "FALSE",
    });
    return true;
  }
}
