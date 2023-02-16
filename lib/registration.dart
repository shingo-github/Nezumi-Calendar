import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nezumi_calendar/email_check.dart';

// アカウント登録ページ
class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  String newUserEmail = ""; // 入力されたメールアドレス
  String newUserPassword = ""; // 入力されたパスワード
  String infoText = ""; // 登録に関する情報を表示
  bool isLoading = false;
  // ignore: non_constant_identifier_names, avoid_init_to_null
  late bool? pswd_OK = null; // パスワードが有効な文字数を満たしているかどうか

  void startLoading() {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
  }

  void endLoading() {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Firebase Authenticationを利用するためのインスタンス
  final FirebaseAuth auth = FirebaseAuth.instance;
  // ignore: prefer_typing_uninitialized_variables
  //var result;
  // ignore: prefer_typing_uninitialized_variables
  //var user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(builder: (context) {
          // ignore: no_leading_underscores_for_local_identifiers
          final _size = MediaQuery.of(context).size;
          return Stack(children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                    padding: EdgeInsets.fromLTRB(25.0, 0, 25.0, 30.0),
                    child: Text('新規アカウントの作成',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))),

                // メールアドレスの入力フォーム
                Padding(
                    padding: const EdgeInsets.fromLTRB(25.0, 0, 25.0, 0),
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: "メールアドレス"),
                      onChanged: (String value) {
                        newUserEmail = value;
                      },
                    )),

                // パスワードの入力フォーム
                Padding(
                  padding: const EdgeInsets.fromLTRB(25.0, 0, 25.0, 10.0),
                  child: TextFormField(
                      decoration:
                          const InputDecoration(labelText: "パスワード（8～20文字）"),
                      obscureText: true, // パスワードが見えないようRにする
                      maxLength: 20, // 入力可能な文字数
                      maxLengthEnforcement: MaxLengthEnforcement
                          .enforced, // 入力可能な文字数の制限を超える場合の挙動の制御
                      onChanged: (String value) {
                        if (value.length >= 8) {
                          newUserPassword = value;
                          pswd_OK = true;
                        } else {
                          pswd_OK = false;
                        }
                      }),
                ),

                // 登録失敗時のエラーメッセージ
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 5.0),
                  child: Text(
                    infoText,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

                ButtonTheme(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      fixedSize: Size(
                        _size.width * 0.86, //70%
                        30,
                      ),
                      foregroundColor: const Color.fromARGB(255, 248, 159, 239),
                      shape: const StadiumBorder(),
                      side: const BorderSide(
                          color: Color.fromARGB(255, 248, 159, 239)),
                    ),
                    child: const Text('ユーザー登録'),
                    onPressed: () async {
                      primaryFocus?.unfocus();
                      if (pswd_OK != null && pswd_OK == true) {
                        try {
                          startLoading();
                          // メール/パスワードでユーザー登録
                          UserCredential result =
                              await auth.createUserWithEmailAndPassword(
                            email: newUserEmail,
                            password: newUserPassword,
                          );

                          // 登録成功
                          // 登録したユーザー情報
                          User user = result.user!;
                          final uuid = user.uid;
                          user.sendEmailVerification();

                          // ignore: use_build_context_synchronously
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Emailcheck(
                                    email: newUserEmail,
                                    password: newUserPassword,
                                    from: 1),
                              ));

                          CollectionReference users =
                              FirebaseFirestore.instance.collection('users');
                          return users.doc(uuid).set({
                            'userid': uuid,
                            'email': newUserEmail,
                          })
                              // ignore: avoid_print
                              .then((value) {
                            if (kDebugMode) {
                              print("新規登録に成功");
                            }
                          })
                              // ignore: avoid_print
                              .catchError(
                                  // ignore: avoid_print, invalid_return_type_for_catch_error
                                  (error) => print("新規登録に失敗しました!: $error"));
                        } on FirebaseAuthException catch (e) {
                          // ユーザー登録に失敗した場合
                          if (e.code == 'email-already-in-use') {
                            if (mounted) {
                              setState(() {
                                infoText = "指定したメールアドレスは登録済みです";
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              });
                            }
                          } else if (e.code == 'invalid-email') {
                            if (mounted) {
                              setState(() {
                                infoText = "メールアドレスのフォーマットが正しくありません";
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              });
                            }
                          } else if (e.code == 'operation-not-allowed') {
                            if (mounted) {
                              setState(() {
                                infoText = "指定したメールアドレス・パスワードは現在使用できません";
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              });
                            }
                          } else if (e.code == 'weak-password') {
                            if (mounted) {
                              setState(() {
                                infoText = "パスワードは8文字以上にしてください";
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              });
                            }
                          }
                        } finally {
                          endLoading();
                        }
                      } else if (pswd_OK == null) {
                        if (mounted) {
                          setState(() {
                            infoText = 'メールアドレス、またはパスワードの欄が空白です';
                          });
                        }
                      } else {
                        if (mounted) {
                          setState(() {
                            infoText = 'パスワードは8文字以上にしてください';
                          });
                        }
                      }
                    },
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(
                      _size.width * 0.82, //70%
                      30,
                    ),
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 248, 159, 239),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("戻る"),
                ),
              ],
            ),
            if (isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: LoadingAnimationWidget.inkDrop(
                    //この部分
                    color: const Color.fromARGB(255, 248, 159, 239),
                    size: 50,
                  ),
                ),
              ),
          ]);
        }),
      ),
    );
  }
}
