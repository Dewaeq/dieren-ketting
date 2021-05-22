import 'package:dieren_ketting/model/constants.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
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
              valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
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
      ),
    );
  }
}
