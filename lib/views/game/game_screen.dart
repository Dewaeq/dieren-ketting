import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dieren_ketting/main.dart';
import 'package:dieren_ketting/model/constants.dart';
import 'package:dieren_ketting/model/user_model.dart';
import 'package:dieren_ketting/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import 'components/clock.dart';
import 'components/member.dart';
import 'components/word.dart';

class GameScreen extends StatefulWidget {
  final String pin;
  final UserModel currentUser;
  final bool isHost;

  const GameScreen({Key key, this.pin, this.currentUser, this.isHost})
      : super(key: key);
  @override
  _GameScreenState createState() => _GameScreenState(
        pin: pin,
        currentUser: currentUser,
        isHost: isHost,
      );
}

class _GameScreenState extends State<GameScreen> {
  final String pin;
  final UserModel currentUser;
  final bool isHost;

  final TextEditingController wordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  _GameScreenState({
    this.pin,
    this.currentUser,
    this.isHost,
  });

  List<UserModel> users = [];
  UserModel currentPlayer;
  bool _enabled = true, _playing = false, _started = false, _kicked = false;
  Stream<DocumentSnapshot> stream;
  int score = 0;
  List<String> allWords = [];
  List<String> order = [];
  List<String> animals = [];

  getAnimals() async {
    var file = (await http.get("assets/data/data.txt")).body;
    var lines = file.split("\n");
    for (var line in lines) {
      if (line.trim() != "") {
        animals.add(line.trim());
      }
    }
    print("gotAnimals");
  }

  kick(UserModel toKick) async {
    if (currentPlayer != null && currentPlayer.uid == toKick.uid) {
      var newCurrentPlayer = getNewPlayer();
      await setCurrentPlayer(newCurrentPlayer);
    }
    print("kicking");
    await StoreMethods().kickUser(pin, toKick);
  }

  startGame() async {
    await StoreMethods().restartGame(pin, users);

    List<String> uids = [];
    for (var user in users) {
      uids.add(user.uid);
    }
    uids.shuffle(new Random());
    order = uids;

    await StoreMethods().startGame(pin, order);
  }

  setCurrentPlayer(UserModel newCurrentPlayer) async {
    await StoreMethods().setCurrentPlayer(newCurrentPlayer, pin);
  }

  submitWord() async {
    score++;

    var nextUser = getNewPlayer();
    var word = wordController.text.toUpperCase();

    await StoreMethods().submitWord(
      word: word,
      score: score,
      pin: pin,
      currentUser: currentUser,
      nextUser: nextUser,
    );
    wordController.text = "";
  }

  restartGame() async {
    await StoreMethods().restartGame(pin, users);
  }

  dontKnowWord() async {
    print("didnt know word");
    var alive = users.where((element) => element.alive == true).toList();
    var nextUser = getNewPlayer();

    var others = alive;
    others.removeWhere((element) => element.uid == currentUser.uid);
    if (others.length == 1) {
      await FirebaseFirestore.instance
          .collection("rooms")
          .doc(pin)
          .collection("members")
          .doc(currentUser.uid)
          .update({
        "alive": "FALSE",
      });
      await FirebaseFirestore.instance.collection("rooms").doc(pin).update({
        "winner": others[0].uid,
      });
      return;
    }

    new Future.delayed(const Duration(seconds: 1), () async {
      await StoreMethods().dontKnowAnswer(
        pin: pin,
        currentUser: currentUser,
        nextUser: nextUser,
      );
    });
  }

  UserModel getNewPlayer() {
    var dead = users.where((e) => e.alive == false).toList();
    List<String> deadUids = [];
    List<String> allUids = [];
    for (var user in dead) {
      deadUids.add(user.uid);
    }
    for (var user in users) {
      allUids.add(user.uid);
    }
    order.removeWhere((e) =>
        (deadUids.contains(e) && e != currentUser.uid) || !allUids.contains(e));

    int myIndex = order.indexOf(currentUser.uid);
    int newIndex = myIndex + 1;
    if (newIndex == order.length) {
      newIndex = 0;
    }
    var newUid = order[newIndex];
    var newUser = users.firstWhere((e) => e.uid == newUid);
    if (!currentUser.alive) {
      order.remove(currentUser.uid);
    }
    return newUser;
  }

  Widget members() {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(pin)
            .collection("members")
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          var docs = snapshot.data.docs;

          var alive = docs
              .where((element) => element.data()['alive'] == "true")
              .toList();
          var dead = docs;
          dead.removeWhere((element) => alive.contains(element));

          /* alive.sort((a, b) {
            return a
                .data()['userName']
                .toString()
                .toLowerCase()
                .compareTo(b.data()['userName'].toString().toLowerCase());
          });
          dead.sort((a, b) {
            return a
                .data()['userName']
                .toString()
                .toLowerCase()
                .compareTo(b.data()['userName'].toString().toLowerCase());
          }); */
          var newDocs = alive + dead;
          bool delete = false;
          List<UserModel> oldUsers = users;
          List<UserModel> toAdd = [];
          List<String> toRemove = [];
          for (int i = 0; i < newDocs.length; i++) {
            var user = UserModel.fromMap(newDocs[i].data());
            if (oldUsers.firstWhere((e) => e.uid == user.uid,
                    orElse: () => null) !=
                null) {
              var oldUser = oldUsers.firstWhere((e) => e.uid == user.uid);
              if (oldUser.alive != user.alive) {
                toAdd.add(user);
                toRemove.add(user.uid);
              } else if (oldUser.score < user.score) {
                toAdd.add(user);
                toRemove.add(user.uid);
              }
            }
            if (oldUsers.firstWhere((e) => e.uid == user.uid,
                    orElse: () => null) ==
                null) {
              toAdd.add(user);
            }
          }

          List<String> allNewUids = [];
          for (var doc in newDocs) {
            var newUser = UserModel.fromMap(doc.data());
            allNewUids.add(newUser.uid);
          }

          if (!allNewUids.contains(currentUser.uid)) {
            WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                  _kicked = true;
                }));
            return Text(
              "KICKED",
              style: TextStyle(
                fontSize: 40,
              ),
            );
          }

          for (var oldUser in oldUsers) {
            if (!allNewUids.contains(oldUser.uid)) {
              toRemove.add(oldUser.uid);
              delete = true;
            }
          }

          if (toAdd.length > 0 || delete) {
            print("setting users");
            WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                  users.removeWhere((e) => toRemove.contains(e.uid));
                  users += toAdd;
                }));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return Member(
                user: users[index],
                currentUser: currentUser,
                kick: (UserModel toKick) {
                  kick(toKick);
                },
                isHost: isHost,
              );
            },
          );
        });
  }

  Widget game(Size size) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("rooms")
                .doc(pin)
                .snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.hasError || !snapshot.hasData) {
                return Text(snapshot.error.toString());
              }
              String word =
                  snapshot.data['currentWord'].toString().toUpperCase();
              String winnerId = snapshot.data['winner'].toString();
              String currentPlayerId =
                  snapshot.data['currentPlayer'].toString();
              if (currentPlayerId == "NONE") {
                return CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
                );
              }

              if (winnerId != "NONE") {
                var winner = users.firstWhere(
                  (element) => element.uid == winnerId,
                  orElse: () => new UserModel(userName: "error"),
                );
                if (winner.userName == "error") {
                  return Text("error");
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Winnaar:",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 34),
                    ),
                    Text(
                      winner.userName,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 65),
                    ),
                    SizedBox(height: 80),
                    isHost
                        ? FlatButton(
                            color: Colors.amber,
                            height: 70,
                            minWidth: 250,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "Restart Game",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            onPressed: () {
                              restartGame();
                            },
                          )
                        : Container()
                  ],
                );
              }

              var newCurrentPlayer = users.firstWhere(
                  (e) => e.uid == currentPlayerId,
                  orElse: () => new UserModel(userName: "error"));

              if (newCurrentPlayer.userName == "error") {
                print("error");
                return CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
                );
              } else if (newCurrentPlayer.uid == currentUser.uid && !_playing) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => setState(() {
                    _playing = true;
                    _enabled = true;
                  }),
                );
                return CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
                );
              } else if (newCurrentPlayer.uid != currentUser.uid && _playing) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => setState(() {
                    _playing = false;
                    _enabled = false;
                  }),
                );
                return CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
                );
              }
              if (currentPlayer == null ||
                  newCurrentPlayer.uid != currentPlayer.uid) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => setState(() {
                    currentPlayer = newCurrentPlayer;
                  }),
                );
                return CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
                );
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Huidig Woord:",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34),
                  ),
                  SizedBox(height: size.height * 0.03),
                  Text(
                    word == "NONE" ? "geen" : "$word",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 65),
                  ),
                  SizedBox(height: size.height * 0.05),
                  Text(
                    "Het is aan:",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    newCurrentPlayer.userName,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                  _playing
                      ? Column(
                          children: [
                            SizedBox(height: size.height * 0.05),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.05),
                              alignment: Alignment.center,
                              child: Form(
                                key: formKey,
                                child: TextFormField(
                                  controller: wordController,
                                  enabled: _enabled,
                                  validator: (value) {
                                    var lastLetter =
                                        word[word.length - 1].toUpperCase();
                                    if (word == "NONE" && value.length > 0)
                                      return null;
                                    if (value.length == 0)
                                      return "Voer een dier in";
                                    if (!animals
                                        .contains(value.toUpperCase())) {
                                      print(value.toUpperCase());
                                      print(animals);
                                      return "Dit dier bestaat niet";
                                    }
                                    if (value[0].toUpperCase() != lastLetter)
                                      return "Voer een geldig dier in";
                                    if (allWords.contains(value.toUpperCase()))
                                      return "Dit dier is al gezegd";
                                    return value.length > 0
                                        ? null
                                        : "Voer een dier in";
                                  },
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.text,
                                  style: TextStyle(
                                    fontSize: 24,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    hintText: "Jouw dier",
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.05),
                            FlatButton(
                              color: backgroundColor,
                              disabledColor: Colors.red[200],
                              disabledTextColor: Colors.white70,
                              height: 70,
                              minWidth: size.width * 0.18,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                "Submit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              onPressed: _enabled
                                  ? () async {
                                      if (formKey.currentState.validate() ||
                                          word == "NONE") {
                                        submitWord();
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        )
                      : Center(
                          child:
                              Text("Wachten op ${newCurrentPlayer.userName}"),
                        ),
                  SizedBox(height: size.height * 0.03),
                  Clock(
                    key: UniqueKey(),
                    timeUp: () {
                      if (_enabled && _playing) {
                        dontKnowWord();
                        setState(() {
                          _enabled = false;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget words() {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(pin)
            .collection("words")
            .orderBy("time")
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          var docs = snapshot.data.docs;
          List<String> toAdd = [];

          for (var i = 0; i < docs.length; i++) {
            var word =
                snapshot.data.docs[i].data()['word'].toString().toUpperCase();
            if (!toAdd.contains(word) && !allWords.contains(word)) {
              toAdd.add(word);
            }
          }
          if (toAdd.length > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                  print("setting words");
                  allWords += toAdd;
                }));
          }

          return ListView.builder(
            itemCount: allWords.length,
            itemBuilder: (context, index) {
              var word = allWords.reversed.toList()[index];
              return Word(
                word: word,
                index: allWords.length - index,
              );
            },
          );
        });
  }

  @override
  void initState() {
    getAnimals();
    super.initState();
    stream =
        FirebaseFirestore.instance.collection("rooms").doc(pin).snapshots();
    stream.listen((event) {
      String orderString = event.data()['order'];
      if (orderString == "NONE") {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
              order.clear();
            }));
      } else {
        List<String> newOrder = orderString.split('|');
        if (newOrder != order) {
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                order = newOrder;
              }));
        }
      }
      bool started = event.data()['started'] == "TRUE";
      if (!_started) {
        _enabled = false;
        _playing = false;
        allWords = [];
      }
      if (started != _started) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
              _started = started;
            }));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: double.infinity,
        alignment: Alignment.center,
        child: _kicked
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Kicked by host",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  FlatButton(
                    color: Colors.amber,
                    height: 70,
                    minWidth: 250,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Quit",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    onPressed: () {
                      navigatorKey.currentState.pushReplacementNamed("/signUp");
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    width: size.width * 0.2,
                    height: size.height,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    child: members(),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    width: size.width * 0.2,
                    height: size.height,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    child: words(),
                  ),
                  Container(
                      width: size.width * 0.6,
                      height: size.height,
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        child: _started
                            ? game(size)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Code:",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 34),
                                  ),
                                  Text(
                                    pin,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 65),
                                  ),
                                  SizedBox(height: 80),
                                  SizedBox(
                                    height: 90,
                                    width: 90,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          backgroundColor),
                                    ),
                                  ),
                                  SizedBox(height: 60),
                                  Text(
                                    "Waiting for other players...",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 90),
                                  isHost
                                      ? FlatButton(
                                          color: Colors.amber,
                                          height: 70,
                                          minWidth: 250,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            "Start Game",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                          onPressed: () {
                                            if (users.length > 1) {
                                              startGame();
                                            } else {
                                              showToast(
                                                'You need to be with at least 2 players, current: ${users.length}',
                                                duration: Duration(seconds: 3),
                                                position: ToastPosition.center,
                                                backgroundColor: Colors.grey,
                                                radius: 7,
                                                textStyle: TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.white,
                                                ),
                                              );
                                            }
                                          },
                                        )
                                      : Container(),
                                ],
                              ),
                      )),
                ],
              ),
      ),
    );
  }
}
