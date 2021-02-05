import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dieren_ketting/model/user_model.dart';
import 'package:flutter/cupertino.dart';

class StoreMethods {
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
      "alive": "true",
      "lastAnswer": "",
      "score": 0,
    });
    return true;
  }

  Future<bool> submitWord({
    @required String word,
    @required int score,
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
    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(pin)
        .collection("members")
        .doc(currentUser.uid)
        .update({
      "score": score,
      "lastAnswer": word,
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
      "alive": "false",
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
}
