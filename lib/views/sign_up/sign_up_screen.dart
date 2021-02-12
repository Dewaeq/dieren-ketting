import 'package:dieren_ketting/main.dart';
import 'package:dieren_ketting/model/constants.dart';
import 'package:dieren_ketting/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:js' as js;

class SignUpScreen extends StatefulWidget {
  SignUpScreen({Key key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();
  TextEditingController pinController = TextEditingController();
  bool _validate = false;
  bool _creatingGame = false;
  bool _loading = false;

  createGame() async {
    setState(() {
      _creatingGame = true;
    });
    await Future.delayed(Duration(seconds: 3));
    String pin = await StoreMethods().createGame();
    var args = new Map<String, dynamic>();
    args['pin'] = pin;
    args['isHost'] = true;
    Map<String, dynamic> fuck = {
      "pin": pin,
      "isHost": true,
    };
    print(fuck['isHost']);
    navigatorKey.currentState.pushNamed(
      "/joinRoom",
      arguments: fuck,
    );
  }

  signUpForGame(String value) async {
    if (formKey.currentState.validate()) {
      setState(() {
        _loading = true;
      });
      print("joining");
      String pin = pinController.text;
      bool exists = await StoreMethods().checkForDocument("rooms", pin);
      print(exists);
      if (exists) {
        print("it exists");
        Map<String, dynamic> args = {
          "pin": pin,
          "isHost": false,
        };
        navigatorKey.currentState.pushNamed(
          "/joinRoom",
          arguments: args,
        );
      } else {
        setState(() {
          _loading = false;
          _validate = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: size.height,
        alignment: Alignment.center,
        child: size.width < 650
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
                    "Sorry, this screen size is currently not supported. Try to rotate your device or use a tablet/pc.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: size.height,
                    ),
                    Column(
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
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]')),
                              ],
                              onFieldSubmitted: (value) => signUpForGame(value),
                              maxLength: 6,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                              ),
                              decoration: InputDecoration(
                                errorText:
                                    _validate ? "Enter a valid code" : null,
                                contentPadding: EdgeInsets.zero,
                                hintText: "165689",
                                counterText: "",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        MaterialButton(
                          color: backgroundColor,
                          height: 70,
                          minWidth: 250,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: _loading
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : Text(
                                  "Join Game",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                          onPressed: _loading
                              ? () {}
                              : () => signUpForGame(pinController.text),
                        ),
                        SizedBox(height: 20),
                        MaterialButton(
                          color: Colors.amber,
                          height: 70,
                          minWidth: 250,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            "Create Game",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          onPressed: () {
                            createGame();
                          },
                        ),
                        SizedBox(height: 70),
                      ],
                    ),
                    _creatingGame
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        backgroundColor),
                                  ),
                                ),
                                SizedBox(height: 50),
                                Text(
                                  "Creating Game",
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              // ),
                            ),
                          )
                        : Container(),
                    Positioned(
                      bottom: 20,
                      child: MaterialButton(
                        onPressed: () {
                          js.context.callMethod('open',
                              ['https://www.github.com/dewaeq/dieren-ketting']);
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              "assets/img/github.png",
                              height: 40,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Source",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
