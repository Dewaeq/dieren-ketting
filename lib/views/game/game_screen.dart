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
  bool _enabled = true,
      _playing = false,
      _started = false,
      _kicked = false,
      _starting = false,
      _restarting = false,
      _checkWords = false,
      _loading = false;
  Stream<DocumentSnapshot> roomStream;
  Stream<QuerySnapshot> membersStream;
  Stream<QuerySnapshot> wordsStream;
  List<String> allWords = [];
  List<String> order = [];
  List<String> animals = [];
  String word = "NONE", winnerId = "NONE", currentPlayerId = "NONE";

  getAnimals() async {
    var file = (await http.get(
            "https://raw.githubusercontent.com/Dewaeq/dieren-ketting/main/web/assets/data/data.txt"))
        .body;
    var lines = file.split("\n");
    List<String> toAdd = [];
    for (var line in lines) {
      if (line.trim() != "") {
        toAdd.add(line.trim());
      }
    }
    if (toAdd.length < 10) throw ("Animal list not found 404");
    setState(() {
      animals = toAdd;
    });
  }

  kick(UserModel toKick) async {
    if (currentPlayer != null && currentPlayer.uid == toKick.uid) {
      var newCurrentPlayer = getNextPlayer();
      await setCurrentPlayer(newCurrentPlayer);
    }
    await StoreMethods().kickUser(pin, toKick);
    var alive =
        users.where((e) => e.alive == true && e.uid != toKick.uid).toList();
    if (alive.length == 1 && winnerId == "NONE") {
      await StoreMethods().setWinner(pin, alive[0]);
    }
  }

  setWinner(UserModel winner) async {
    await StoreMethods().setWinner(pin, winner);
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
          winnerId = winner.uid;
        }));
  }

  startGame() async {
    setState(() => _starting = true);

    await StoreMethods().restartGame(pin, users);

    List<String> uids = [];
    for (var user in users) {
      uids.add(user.uid);
    }
    uids.shuffle(new Random());
    order = uids;

    await StoreMethods().startGame(pin, order);
    setState(() => _starting = false);
  }

  setCurrentPlayer(UserModel newCurrentPlayer) async {
    await StoreMethods().setCurrentPlayer(newCurrentPlayer, pin);
  }

  submitWord(String value) async {
    if (!formKey.currentState.validate()) return;

    setState(() => _enabled = false);

    var nextUser = getNextPlayer();

    await StoreMethods().submitWord(
      word: value,
      pin: pin,
      currentUser: currentUser,
      nextUser: nextUser,
    );
    wordController.text = "";
  }

  aproveWord(String value) async {
    await StoreMethods().aproveWord(pin, value);
  }

  restartGame() async {
    setState(() => _restarting = true);
    await StoreMethods().restartGame(pin, users);
    setState(() => _restarting = false);
  }

  dontKnowWord() async {
    currentUser.alive = false;

    var alive = users.where((element) => element.alive == true).toList();
    var nextUser = getNextPlayer();

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
      await StoreMethods().setWinner(pin, others[0]);
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

  UserModel getNextPlayer() {
    var dead = users.where((e) => !e.alive).toList();
    List<String> deadUids = [];
    List<String> allUids = [];
    for (var user in dead) {
      deadUids.add(user.uid);
    }
    for (var user in users) {
      allUids.add(user.uid);
    }
    order.removeWhere(
      (e) =>
          (deadUids.contains(e) && e != currentUser.uid) ||
          !allUids.contains(e),
    );

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
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return Member(
          currentUser: currentUser,
          isHost: isHost,
          user: users[index],
          kick: (UserModel toKick) => kick(toKick),
          key: UniqueKey(),
        );
      },
    );
  }

  Widget game(Size size) {
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
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("error"),
            isHost ? restartGameButton() : Container(),
          ],
        );
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Winnaar:",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34),
          ),
          Text(
            winner.userName,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 65),
          ),
          SizedBox(height: 80),
          isHost ? restartGameButton() : Container()
        ],
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
          currentPlayer.userName,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        _playing
            ? Column(
                children: [
                  SizedBox(height: size.height * 0.05),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.05),
                    alignment: Alignment.center,
                    child: Form(
                      key: formKey,
                      child: TextFormField(
                        controller: wordController,
                        enabled: _enabled,
                        validator: (value) {
                          var lastLetter = word[word.length - 1].toUpperCase();
                          if (value.length == 0) return "Voer een dier in";
                          if (_checkWords &&
                              animals.length > 10 &&
                              !animals.contains(value.trim().toUpperCase())) {
                            aproveWord(value.trim().toUpperCase());
                            return "Dit dier bestaat niet";
                          }
                          if (word == "NONE" && value.length > 0) return null;
                          if (value[0].toUpperCase() != lastLetter)
                            return "Voer een geldig dier in";
                          if (allWords.contains(value.trim().toUpperCase()))
                            return "Dit dier is al gezegd";
                          return value.length > 0 ? null : "Voer een dier in";
                        },
                        onFieldSubmitted: (value) => submitWord(value.trim()),
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
                  MaterialButton(
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
                        ? () => submitWord(wordController.text.trim())
                        : null,
                  ),
                ],
              )
            : Center(
                child: Text("Wachten op ${currentPlayer.userName}"),
              ),
        SizedBox(height: size.height * 0.03),
        Clock(
          key: Key(currentPlayerId + word),
          timeUp: () {
            if (_enabled &&
                _playing &&
                _started &&
                currentPlayerId == currentUser.uid) {
              dontKnowWord();
              setState(() {
                _enabled = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget restartGameButton() {
    return MaterialButton(
      color: Colors.amber,
      height: 70,
      minWidth: 250,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: _restarting
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : Text(
              "Restart Game",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
      onPressed: _restarting
          ? () {}
          : () {
              restartGame();
            },
    );
  }

  Widget words() {
    if (allWords.length == 0) return Container();

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
  }

  listenRoom() async {
    roomStream =
        FirebaseFirestore.instance.collection("rooms").doc(pin).snapshots();
    roomStream.listen((event) {
      String newWord = event.data()['currentWord'].toString().toUpperCase();
      String newWinnerId = event.data()['winner'].toString();
      String newCurrentPlayerId = event.data()['currentPlayer'].toString();
      bool started = event.data()['started'] == "TRUE";
      bool checkWords = event.data()['checkWords'] == "TRUE";

      if (started != _started) {
        setState(() {
          _started = started;
          if (!started) {
            word = "NONE";
            currentPlayerId = "NONE";
            winnerId = "NONE";
            currentPlayer = null;
            allWords.clear();
            _playing = false;
            _enabled = false;
            _restarting = false;
            _starting = false;
          }
        });
      }
      if (newWord == "NONE" && _checkWords != checkWords && mounted) {
        setState(() {
          _checkWords = checkWords;
        });
      }

      if (users.length == 0 || newCurrentPlayerId == "NONE") {
        return;
      }

      if (newWord != "NONE" && newWord != word) {
        setState(() {
          word = newWord;
        });
      }
      if (newWinnerId != "NONE" && newWinnerId != winnerId) {
        setState(() {
          winnerId = newWinnerId;
        });
      }
      var newCurrentPlayer = users.firstWhere(
          (e) => e.uid == newCurrentPlayerId,
          orElse: () => throw ("fuck dit"));
      if (newCurrentPlayer.userName == "won_game_won") return;

      if (_playing && currentUser.uid != newCurrentPlayerId) {
        setState(() {
          _playing = false;
          _enabled = false;
          currentPlayer = newCurrentPlayer;
          currentPlayerId = newCurrentPlayerId;
        });
      } else if (!_playing && currentUser.uid == newCurrentPlayerId) {
        setState(() {
          _playing = true;
          _enabled = true;
          currentPlayer = currentUser;
          currentPlayerId = newCurrentPlayerId;
        });
      } else if (currentPlayerId != newCurrentPlayerId) {
        setState(() {
          currentPlayer = newCurrentPlayer;
          currentPlayerId = newCurrentPlayerId;
        });
      }

      String orderString = event.data()['order'];
      if (orderString == "NONE") {
        setState(() {
          order.clear();
        });
      } else {
        List<String> newOrder = orderString.split('|');
        if (newOrder != order) {
          setState(() {
            order = newOrder;
          });
        }
      }
      if (!_started) {
        _enabled = false;
        _playing = false;
        allWords.clear();
        currentPlayer = null;
        currentPlayerId = "NONE";
        winnerId = "NONE";
        word = "NONE";
      }
      if (started != _started) {
        setState(() {
          _started = started;
          if (!started) {
            _enabled = false;
            _playing = false;
            allWords.clear();
            currentPlayer = null;
            currentPlayerId = "NONE";
            winnerId = "NONE";
            word = "NONE";
          }
        });
      }
    });
  }

  listenWords() async {
    wordsStream = FirebaseFirestore.instance
        .collection("rooms")
        .doc(pin)
        .collection("words")
        .snapshots();
    wordsStream.listen((event) {
      var docs = event.docChanges;
      if (docs.length == 0) return;

      if (docs[0].type == DocumentChangeType.removed) {
        setState(() => allWords.clear());
        return;
      }

      List<String> toAdd = [];

      for (var i = 0; i < docs.length; i++) {
        var word = docs[i].doc.data()['word'].toString().toUpperCase();
        if (!toAdd.contains(word) && !allWords.contains(word)) {
          toAdd.add(word);
        }
      }
      if (toAdd.length > 0) {
        setState(() {
          allWords += toAdd;
        });
      }
    });
  }

  listenMembers() async {
    membersStream = FirebaseFirestore.instance
        .collection("rooms")
        .doc(pin)
        .collection("members")
        .snapshots();
    membersStream.listen((event) {
      var docs = event.docChanges;
      var alive = docs.where((e) => e.doc.data()['alive'] == "TRUE").toList();
      var dead = docs;
      dead.removeWhere((e) => alive.contains(e));

      var newDocs = alive + dead;
      bool delete = false;
      List<UserModel> oldUsers = users;
      List<UserModel> toAdd = [];
      List<String> toRemove = [];
      for (int i = 0; i < newDocs.length; i++) {
        if (newDocs[i].type == DocumentChangeType.removed) {
          toRemove.add(newDocs[i].doc.data()['uid']);
          delete = true;
        } else {
          var user = UserModel.fromMap(newDocs[i].doc.data());
          if (oldUsers.firstWhere((e) => e.uid == user.uid,
                  orElse: () => null) !=
              null) {
            var oldUser = oldUsers.firstWhere((e) => e.uid == user.uid);
            if (oldUser.alive != user.alive) {
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
      }
      List<String> toAddUids = [];
      for (var user in toAdd) {
        toAddUids.add(user.uid);
      }

      if (toRemove.contains(currentUser.uid) &&
          !toAddUids.contains(currentUser.uid)) {
        setState(() {
          _kicked = true;
        });
        return;
      }

      if (toAdd.length > 0 || delete) {
        setState(() {
          users.removeWhere((e) => toRemove.contains(e.uid));
          users += toAdd;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getAnimals();
    listenRoom();
    listenMembers();
    listenWords();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
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
                      MaterialButton(
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
                          navigatorKey.currentState
                              .pushReplacementNamed("/signUp");
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
                                          ? Column(
                                              children: [
                                                MaterialButton(
                                                  color: Colors.amber,
                                                  height: 70,
                                                  minWidth: 250,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  child: _starting
                                                      ? CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  Colors.white),
                                                        )
                                                      : Text(
                                                          "Start Game",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 24,
                                                          ),
                                                        ),
                                                  onPressed: _starting
                                                      ? () {}
                                                      : () {
                                                          if (users.length >
                                                              1) {
                                                            startGame();
                                                          } else {
                                                            showToast(
                                                              'You need to be with at least 2 players, current: ${users.length}',
                                                              duration:
                                                                  Duration(
                                                                      seconds:
                                                                          3),
                                                              position:
                                                                  ToastPosition
                                                                      .center,
                                                              backgroundColor:
                                                                  Colors.grey,
                                                              radius: 7,
                                                              textStyle:
                                                                  TextStyle(
                                                                fontSize: 24,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                ),
                                                SizedBox(height: 50),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Check if animal exists: ",
                                                      style: TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Switch(
                                                      value: _checkWords,
                                                      activeColor:
                                                          backgroundColor,
                                                      onChanged: (value) async {
                                                        setState(() {
                                                          _loading = true;
                                                        });
                                                        await StoreMethods()
                                                            .setCheckWords(
                                                                pin, value);
                                                        await Future.delayed(
                                                            Duration(
                                                          seconds: 1,
                                                          milliseconds: 300,
                                                        ));
                                                        setState(() {
                                                          _checkWords = value;
                                                          _loading = false;
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                          : Container(),
                                    ],
                                  ),
                          )),
                    ],
                  ),
          ),
          _loading
              ? Container(
                  height: size.height,
                  color: Colors.grey.withOpacity(.7),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(backgroundColor),
                        ),
                      ),
                      SizedBox(height: 50),
                      Text(
                        "Loading",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    // ),
                  ),
                )
              : Container()
        ],
      ),
    );
  }
}
