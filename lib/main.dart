// ignore: duplicate_ignore
// ignore_for_file: no_leading_underscores_for_local_identifiers, duplicate_ignore, use_build_context_synchronously

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nezumi_calendar/app_splash_page.dart';
import 'package:nezumi_calendar/login_page.dart';
import 'package:nezumi_calendar/shift_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initializeDateFormatting('ja_JP').then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nezumi Calendar',
        theme: ThemeData(
          appBarTheme:
              const AppBarTheme(color: Color.fromARGB(255, 248, 159, 239)),
          fontFamily: 'Murecho',
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: ((context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // スプラッシュ画面などに書き換えても良い
              return const AppSplashPage();
            }
            if (snapshot.hasData) {
              // User が null でなない、つまりサインイン済みのホーム画面へ
              return const ShiftCalendar(
                user_id: null,
              );
            }
            // User が null である、つまり未サインインのサインイン画面へ
            return const LoginPage();
          }),
        ));
  }
}
