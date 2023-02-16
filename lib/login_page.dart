import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nezumi_calendar/email_check.dart';
import 'package:nezumi_calendar/registration.dart';
import 'package:nezumi_calendar/shift_calendar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

// ignore: duplicate_ignore
class _LoginPageState extends State<LoginPage> {
  // メッセージ表示用
  String infoText = '';
  // 入力したメールアドレス・パスワード
  String newUserEmail = '';
  String newUserPassword = '';
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

  // FirebaseAuthが用意しているメールアドレスとパスワードを登録する関数を定義
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final _size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Builder(builder: (context) {
          return Stack(children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Image.asset(
                      'assets/images/nezumi_splash02.png',
                    ),
                  ),

                  // メールアドレス入力
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'メールアドレス'),
                    onChanged: (String value) {
                      if (mounted) {
                        setState(() {
                          newUserEmail = value;
                        });
                      }
                    },
                  ),

                  TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'パスワード（8～20文字）'),
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
                  Flexible(
                      child: Container(
                    padding: const EdgeInsets.all(20),
                    // メッセージ表示
                    child: Text(
                      infoText,
                      style: const TextStyle(color: Colors.red),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 4,
                    ),
                  )),
                  // ignore: sized_box_for_whitespace
                  Container(
                    width: double.infinity,
                    // ログイン登録ボタン
                    child: Builder(builder: (context) {
                      return OutlinedButton(
                        // ignore: sort_child_properties_last
                        child: const Text('ログイン'),
                        style: OutlinedButton.styleFrom(
                          fixedSize: Size(
                            _size.width * 0.5, //70%
                            30,
                          ),
                          foregroundColor:
                              const Color.fromARGB(255, 248, 159, 239),
                          shape: const StadiumBorder(),
                          side: const BorderSide(
                              color: Color.fromARGB(255, 248, 159, 239)),
                        ),
                        onPressed: () async {
                          primaryFocus?.unfocus();
                          //await showLoadingDialog(context, timeoutSec: 10);
                          if (pswd_OK != null && pswd_OK == true) {
                            try {
                              startLoading();
                              // メール/パスワードでログイン
                              UserCredential result =
                                  await auth.signInWithEmailAndPassword(
                                email: newUserEmail,
                                password: newUserPassword,
                              );

                              // ログインに成功した場合
                              // チャット画面に遷移＋ログイン画面を破棄
                              // ignore: use_build_context_synchronously, unnecessary_null_comparison
                              User? user = result.user;
                              final uuid = user?.uid;

                              if (result.user!.emailVerified) {
                                // ignore: use_build_context_synchronously
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return ShiftCalendar(user_id: uuid);
                                }));
                              } else {
                                // ignore: use_build_context_synchronously
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Emailcheck(
                                          email: newUserEmail,
                                          password: newUserPassword,
                                          from: 2)),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              if (kDebugMode) {
                                print(e.code);
                              }
                              // ログインに失敗した場合
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
                              } else if (e.code == 'user-not-found') {
                                infoText = "アカウントが作成されていません";
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              } else if (e.code == 'wrong-password') {
                                infoText = "パスワードが違います";
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
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
                          //hideLoadingDialog();
                        },
                      );
                    }),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Builder(builder: (context) {
                        return ButtonTheme(
                          minWidth: 350.0,
                          // height: 100.0,
                          child: OutlinedButton(
                              style: ElevatedButton.styleFrom(
                                fixedSize: Size(
                                  _size.width * 0.86, //70%
                                  30,
                                ),
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(255, 248, 159, 239),
                                shape: const StadiumBorder(),
                              ),

                              // ボタンクリック後にアカウント作成用の画面の遷移する。
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (BuildContext context) =>
                                        const Registration(),
                                  ),
                                );
                              },
                              child: const Text(
                                'アカウントを作成する',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                        );
                      }),
                    ),
                    TextButton(
                        child: const Text('パスワードをお忘れの方'),
                        onPressed: () async {
                          startLoading();
                          try {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(email: newUserEmail);
                            if (mounted) {
                              setState(() {
                                infoText = 'パスワードリセット用のメールを送信しました';
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                infoText =
                                    '登録済みのメールアドレスを入力し「パスワードをお忘れの方」のリンクをを押してください';
                              });
                            }
                          } finally {
                            endLoading();
                          }
                        }),
                  ]),
                ],
              ),
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
