import 'dart:async';

import 'package:dieren_ketting/model/constants.dart';
import 'package:flutter/material.dart';

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
        setState(() => _start--);
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
              strokeWidth: 7,
              backgroundColor: Colors.grey[200],
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
