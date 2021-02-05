import 'package:dieren_ketting/model/user_model.dart';
import 'package:dieren_ketting/views/game/game_screen.dart';
import 'package:dieren_ketting/views/join_game/join_game_screen.dart';
import 'package:flutter/material.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case "/joinRoom":
        if (args is String) {
          return MaterialPageRoute(
            builder: (context) => JoinGameScreen(
              pin: args,
            ),
          );
        }
        return errorRoute();
      case "/gameScreen":
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (context) => GameScreen(
              currentUser: args['currentUser'],
              pin: args['pin'],
            ),
          );
        }
        return errorRoute();
      case "/error":
        return errorRoute();

      case "/loading":
        return loadingRoute();

      default:
        return errorRoute();
    }
  }

  static Route<dynamic> errorRoute() {
    return MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: Text(
              "404",
              style: TextStyle(
                fontSize: 35,
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  static Route<dynamic> loadingRoute() {
    return MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Text(
                "Loading",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
