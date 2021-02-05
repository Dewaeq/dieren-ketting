import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dieren_ketting/model/constants.dart';
import 'package:dieren_ketting/model/user_model.dart';
import 'package:dieren_ketting/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart';

class JoinGameScreen extends StatefulWidget {
  final String pin;

  const JoinGameScreen({Key key, this.pin}) : super(key: key);
  @override
  _JoinGameScreenState createState() => _JoinGameScreenState(pin: pin);
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final String pin;

  _JoinGameScreenState({@required this.pin});

  final formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
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
              child: Text(
                "Submit",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              onPressed: () async {
                if (formKey.currentState.validate()) {
                  var uid = Uuid().v4();
                  await StoreMethods()
                      .joinGame(pin, nameController.text.trim(), uid);
                  var currentUser = new UserModel(
                      alive: true,
                      userName: nameController.text.trim(),
                      uid: uid,
                      lastAnswer: "");
                  var args = new Map<String, dynamic>();
                  args['pin'] = pin;
                  args['currentUser'] = currentUser;
                  navigatorKey.currentState
                      .pushNamed("/gameScreen", arguments: args);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
