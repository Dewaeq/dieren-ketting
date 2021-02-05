import 'package:dieren_ketting/routes/route_generator.dart';
import 'package:dieren_ketting/views/sign_up/sign_up_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final MaterialColor swatchColor = const MaterialColor(
    0xffFC402C,
    const <int, Color>{
      50: const Color(0xffFC402C),
      100: const Color(0xffFC402C),
      200: const Color(0xffFC402C),
      300: const Color(0xffFC402C),
      400: const Color(0xffFC402C),
      500: const Color(0xffFC402C),
      600: const Color(0xffFC402C),
      700: const Color(0xffFC402C),
      800: const Color(0xffFC402C),
      900: const Color(0xffFC402C),
    },
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          fontFamily: "ProductSans",
          primarySwatch: Colors.grey,
        ),
        onGenerateRoute: RouteGenerator.generateRoute,
        home: SignUpScreen(),
      ),
    );
  }
}
