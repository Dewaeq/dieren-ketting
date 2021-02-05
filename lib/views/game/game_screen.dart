import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dieren_ketting/model/constants.dart';
import 'package:dieren_ketting/model/user_model.dart';
import 'package:dieren_ketting/services/firestore.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  final String pin;
  final UserModel currentUser;

  const GameScreen({Key key, this.pin, this.currentUser}) : super(key: key);
  @override
  _GameScreenState createState() => _GameScreenState(
        pin: pin,
        currentUser: currentUser,
      );
}

class _GameScreenState extends State<GameScreen> {
  final String pin;
  final UserModel currentUser;

  final TextEditingController wordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  _GameScreenState({
    @required this.pin,
    @required this.currentUser,
  });

  List<UserModel> users = [];
  bool _enabled = true, _playing = false, _started = false, _won = false;
  Stream<DocumentSnapshot> stream;
  int score = 0;
  Map<String, List<String>> allWords = {
    "words": [],
    "answerers": [],
  };

  setCurrentPlayer(UserModel newCurrentPlayer) async {
    await StoreMethods().setCurrentPlayer(newCurrentPlayer, pin);
  }

  submitWord() async {
    score++;
    var alive = users.where((element) => element.alive == true).toList();
    var myIndex = alive.lastIndexWhere(
      (element) => element.uid == currentUser.uid,
    );
    int nextIndex = myIndex + 1;
    print("my name: ${currentUser.userName}");
    print("max length: ${alive.length}");
    print("next index: $nextIndex");
    if (myIndex == alive.length - 1) {
      nextIndex = 0;
    }
    var nextUser = alive[nextIndex];
    var word = wordController.text.toUpperCase();

    await StoreMethods().submitWord(
      word: word,
      score: score,
      pin: pin,
      currentUser: currentUser,
      nextUser: nextUser,
    );
  }

  dontKnowWord() async {
    print("didnt know word");
    var alive = users.where((element) => element.alive == true).toList();
    var myIndex = alive.lastIndexWhere(
      (element) => element.uid == currentUser.uid,
    );
    int nextIndex = myIndex + 1;
    if (myIndex == alive.length - 1) {
      nextIndex = 0;
    }
    var nextUser = alive[nextIndex];

    var others = alive;
    others.removeWhere((element) => element.uid == currentUser.uid);
    if (others.length == 1) {
      await FirebaseFirestore.instance
          .collection("rooms")
          .doc(pin)
          .collection("members")
          .doc(currentUser.uid)
          .update({
        "alive": "false",
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

  Widget members() {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(pin)
            .collection("members")
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          print("updating");
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
          List<UserModel> toAdd = [];

          for (var i = 0; i < newDocs.length; i++) {
            var user = UserModel.fromMap(newDocs[i].data());
            var inUsers = users.firstWhere(
              (element) =>
                  element.uid == user.uid && element.alive == user.alive,
              orElse: () => new UserModel(userName: "error"),
            );
            var inToAdd = toAdd.firstWhere(
              (element) =>
                  element.uid == user.uid && element.alive == user.alive,
              orElse: () => new UserModel(userName: "error"),
            );
            if (inToAdd.userName == "error" && inUsers.userName == "error") {
              toAdd.add(user);
            }
          }
          if (toAdd.length > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                  print("setting state");
                  users = users + toAdd;
                }));
          }

          return ListView.builder(
            itemCount: newDocs.length,
            itemBuilder: (context, index) {
              var user = UserModel.fromMap(newDocs[index].data());
              return Member(user: user);
            },
          );
        });
  }

  Widget game(Size size) {
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collection("rooms").doc(pin).snapshots(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return Text(snapshot.error.toString());
        }
        String word = snapshot.data['currentWord'].toString().toUpperCase();
        String winnerId = snapshot.data['winner'].toString();
        String currentPlayerId = snapshot.data['currentPlayer'].toString();

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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34),
              ),
              Text(
                winner.userName,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 65),
              ),
            ],
          );
        }

        var currentPlayer = users.firstWhere(
            (element) => element.uid == currentPlayerId,
            orElse: () => new UserModel(userName: "error"));
        if (currentPlayer.userName == "error") {
          currentPlayer = currentUser;
          setCurrentPlayer(currentPlayer);
        }
        if (currentPlayer.uid == currentUser.uid && !_playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                _playing = true;
              }));
        }
        if (currentPlayer.uid != currentUser.uid && _playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                _playing = false;
              }));
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
                              var lastLetter =
                                  word[word.length - 1].toUpperCase();
                              if (value.length == 0) return "Voer een dier in";
                              if (value[0].toUpperCase() != lastLetter)
                                return "Voer een geldig dier in";
                              if (allWords['words']
                                  .contains(value.toUpperCase()))
                                return "Dit dier is al gezegd";
                              return value.length > 0
                                  ? null
                                  : "Voer een dier in";
                            },
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
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
                    child: Text("Wachten op ${currentPlayer.userName}"),
                  ),
            SizedBox(height: size.height * 0.03),
            Clock(
              key: UniqueKey(),
              timeUp: () {
                var alive =
                    users.where((element) => element.alive == true).toList();
                if (alive.length <= 1) {
                  var winner = alive[0];
                  print("fuuuuck");
                }
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
            if (!toAdd.contains(word) && !allWords['words'].contains(word)) {
              toAdd.add(word);
            }
          }
          if (toAdd.length > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                  print("setting words state");
                  allWords['words'] += toAdd;
                }));
          }

          return ListView.builder(
            itemCount: allWords['words'].length,
            itemBuilder: (context, index) {
              var word = allWords['words'].reversed.toList()[index];
              return Word(word: word);
            },
          );
        });
  }

  @override
  void initState() {
    super.initState();
    stream =
        FirebaseFirestore.instance.collection("rooms").doc(pin).snapshots();
    stream.listen((event) {
      bool started = event.data()['started'] == "TRUE";
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
        width: size.width,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              width: size.width * 0.2,
              height: size.height,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Colors.black,
                    width: 4,
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
                    width: 4,
                  ),
                ),
              ),
              child: words(),
            ),
            Container(
              width: size.width * 0.6,
              height: size.height,
              child: _started
                  ? game(size)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 90,
                          width: 90,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(backgroundColor),
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
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class Member extends StatelessWidget {
  final UserModel user;

  const Member({
    Key key,
    this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: user.alive ? redAccentColor : Colors.red[200],
                  shape: BoxShape.circle,
                ),
                child: user.alive
                    ? Container()
                    : Icon(
                        Icons.clear,
                        size: 32,
                        color: Colors.red[800],
                      ),
              ),
              Text(
                user.userName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(width: 15),
          Text(
            user.userName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class Word extends StatelessWidget {
  final String word;

  const Word({Key key, this.word}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(word),
    );
  }
}

class Clock extends StatefulWidget {
  final Function timeUp;

  const Clock({Key key, @required this.timeUp}) : super(key: key);
  @override
  _ClockState createState() => _ClockState(timeUp: timeUp);
}

class _ClockState extends State<Clock> {
  final Function timeUp;
  Timer _timer;
  int _max = 20;
  int _start;
  bool done = false;

  _ClockState({this.timeUp});

  @override
  void initState() {
    _start = _max;
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        timeUp();
        setState(() {
          done = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: size.height * 0.1,
            width: size.height * 0.1,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
              value: _start / _max,
            ),
          ),
          Text(
            done ? "Tijd is om" : _start.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
