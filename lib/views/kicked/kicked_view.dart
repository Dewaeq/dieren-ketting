import 'package:dieren_ketting/main.dart';
import 'package:flutter/material.dart';

class KickedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
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
            navigatorKey.currentState.pushReplacementNamed("/signUp");
          },
        ),
      ],
    );
  }
}
