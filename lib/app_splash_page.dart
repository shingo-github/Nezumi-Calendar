import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class AppSplashPage extends StatefulWidget {
  const AppSplashPage({super.key});

  @override
  State<StatefulWidget> createState() => _AppSplashPageState();
}

class _AppSplashPageState extends State<AppSplashPage> {
  // ignore: unused_element
  _AppSplashPageState({Key? key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
            child: RiveAnimation.asset(
      'assets/splash/app_splash_nezumi.riv',
      alignment: Alignment.center,
      fit: BoxFit.contain,
      //animations: 'all',
    )));
  }
}
