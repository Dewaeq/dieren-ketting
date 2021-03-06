import 'package:dieren_ketting/views/game/game_screen.dart';
import 'package:dieren_ketting/views/join_game/join_game_screen.dart';
import 'package:dieren_ketting/views/sign_up/sign_up_screen.dart';
import 'package:flutter/material.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case "/signUp":
        return MaterialPageRoute(
          builder: (_) => SignUpScreen(),
        );

      case "/joinRoom":
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => JoinGameScreen(
              pin: args['pin'],
              isHost: args['isHost'],
            ),
          );
        }
        return errorRoute();
      case "/gameScreen":
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => GameScreen(
              currentUser: args['currentUser'],
              pin: args['pin'],
              isHost: args['isHost'],
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
      builder: (_) {
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
      builder: (_) {
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
