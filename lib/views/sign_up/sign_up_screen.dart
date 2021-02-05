import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dieren_ketting/main.dart';
import 'package:dieren_ketting/model/constants.dart';
import 'package:dieren_ketting/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({Key key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();
  TextEditingController pinController = TextEditingController();
  bool _validate = false;

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
              "Dierenketting",
              style: TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: size.height * 0.08),
            Text(
              "Game Pin:",
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 40),
            Container(
              height: 100,
              width: size.width * 0.3,
              child: Form(
                key: formKey,
                child: TextFormField(
                  controller: pinController,
                  validator: (value) {
                    return value.replaceAll(' ', '').length == 6
                        ? null
                        : "Enter a valid code";
                  },
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                  ),
                  decoration: InputDecoration(
                    errorText: _validate ? "Enter a valid code" : null,
                    contentPadding: EdgeInsets.zero,
                    hintText: "165689",
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
                "Join Game",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              onPressed: () async {
                if (formKey.currentState.validate()) {
                  String pin = pinController.text;
                  bool exists =
                      await StoreMethods().checkForDocument("rooms", pin);
                  if (exists) {
                    navigatorKey.currentState.pushNamed(
                      "/joinRoom",
                      arguments: pin,
                    );
                  } else {
                    setState(() {
                      _validate = true;
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
