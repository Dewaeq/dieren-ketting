import 'package:dieren_ketting/model/constants.dart';
import 'package:dieren_ketting/model/user_model.dart';
import 'package:flutter/material.dart';

class Member extends StatelessWidget {
  final UserModel user;
  final UserModel currentUser;
  final Function(UserModel toKick) kick;
  final bool isHost;

  const Member({
    Key key,
    this.user,
    this.currentUser,
    this.kick,
    this.isHost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          isHost && user.uid != currentUser.uid
              ? Container(
                  width: 50,
                  height: 50,
                  child: MaterialButton(
                    onPressed: () {
                      kick(user);
                    },
                    shape: CircleBorder(),
                    padding: EdgeInsets.zero,
                    color: backgroundColor,
                    child: Center(
                      child: Text(
                        "KICK",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
