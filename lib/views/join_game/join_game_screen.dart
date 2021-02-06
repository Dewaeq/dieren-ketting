import 'package:dieren_ketting/model/constants.dart';
import 'package:dieren_ketting/model/user_model.dart';
import 'package:dieren_ketting/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart';

class JoinGameScreen extends StatefulWidget {
  final String pin;
  final bool isHost;

  const JoinGameScreen({Key key, this.pin, this.isHost}) : super(key: key);
  @override
  _JoinGameScreenState createState() =>
      _JoinGameScreenState(pin: pin, isHost: isHost);
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final String pin;
  final bool isHost;

  _JoinGameScreenState({this.pin, this.isHost});

  final formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: size.height,
        child: Container(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Name",
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: size.height * 0.08),
                Container(
                  height: 100,
                  width: size.width * 0.3,
                  child: Form(
                    key: formKey,
                    child: TextFormField(
                      controller: nameController,
                      validator: (value) {
                        return value.replaceAll(' ', '').length > 2
                            ? null
                            : "Enter a valid name";
                      },
                      maxLength: 20,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        hintText: "Jan",
                        counterText: "",
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                FlatButton(
                  color: backgroundColor,
                  height: 70,
                  minWidth: 250,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: _loading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                  onPressed: _loading
                      ? () {}
                      : () async {
                          if (formKey.currentState.validate()) {
                            setState(() {
                              _loading = true;
                            });
                            print("submitting");
                            var uid = Uuid().v4();
                            await StoreMethods()
                                .joinGame(pin, nameController.text.trim(), uid);
                            var currentUser = new UserModel(
                                alive: true,
                                userName: nameController.text.trim(),
                                uid: uid,
                                lastAnswer: "");
                            var args = {
                              "pin": pin,
                              "currentUser": currentUser,
                              "isHost": isHost,
                            };
                            navigatorKey.currentState
                                .pushNamed("/gameScreen", arguments: args);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
