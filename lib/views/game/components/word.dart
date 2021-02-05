import 'package:dieren_ketting/model/constants.dart';
import 'package:flutter/material.dart';

class Word extends StatelessWidget {
  final String word;
  final int index;

  const Word({Key key, this.word, this.index}) : super(key: key);
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
                  color: redAccentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                index.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(width: 15),
          Text(
            word,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
