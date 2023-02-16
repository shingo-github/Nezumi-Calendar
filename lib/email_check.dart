// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nezumi_calendar/shift_calendar.dart';

class Emailcheck extends StatefulWidget {
  // 呼び出し元Widgetから受け取った後、変更をしないためfinalを宣言。
  final String? email;
  final String? password;
  final int? from; //1 → アカウント作成画面から    2 → ログイン画面から

  const Emailcheck({Key? key, @required this.email, this.password, this.from})
      : super(key: key);

  @override
  _Emailcheck createState() => _Emailcheck();
}

class _Emailcheck extends State<Emailcheck> {
  bool isLoading = false;
  final auth = FirebaseAuth.instance;
  String _nocheckText = '';
  String _sentEmailText = '';
  // ignore: non_constant_identifier_names
  int _btn_click_num = 0;
  // 前画面から受け取った値はNull許容のため、入れ直し用の変数を用意
  late String _newUserEmail;
  late String _newUserPassword;

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

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final _size = MediaQuery.of(context).size;
    _newUserEmail = widget.email ?? '';
    _newUserPassword = widget.password ?? '';

    // 前画面から遷移後の初期表示内容
    if (_btn_click_num == 0) {
      if (widget.from == 1) {
        // アカウント作成画面から遷移した時
        _nocheckText = '';
        _sentEmailText = '${widget.email}\nに確認メールを送信しました。';
      } else {
        _nocheckText = 'まだメール確認が完了していません。\n確認メール内のリンクをクリックしてください。';
        _sentEmailText = '';
      }
    }

    return Scaffold(
      // メイン画面
      body: Center(
        child: Builder(builder: (context) {
          return Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 確認メール未完了時のメッセージ
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                    child: Text(
                      _nocheckText,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                  // 確認メール送信時のメッセージ
                  Text(_sentEmailText),

                  // 確認メールの再送信ボタン
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 30.0),
                    child: ButtonTheme(
                      minWidth: 200.0,
                      // height: 100.0,
                      child: ElevatedButton(
                        // ボタンの形状や背景色など
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.grey, //text-color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        // ボタン内の文字や書式
                        child: const Text(
                          '確認メールを再送信',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        onPressed: () async {
                          UserCredential result =
                              await auth.signInWithEmailAndPassword(
                            email: _newUserEmail,
                            password: _newUserPassword,
                          );
                          User user = result.user!;
                          user.sendEmailVerification();
                          setState(() {
                            _btn_click_num++;
                            _sentEmailText = '${widget.email}\nに確認メールを送信しました。';
                          });
                        },
                      ),
                    ),
                  ),

                  // メール確認完了のボタン配置（Home画面に遷移）
                  SizedBox(
                    width: 350.0,
                    // height: 100.0,
                    child: ElevatedButton(
                      // ボタンの形状や背景色など
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

                      // ボタン内の文字や書式
                      child: const Text(
                        'メール確認完了',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      onPressed: () async {
                        try {
                          startLoading();
                          UserCredential result =
                              await auth.signInWithEmailAndPassword(
                            email: _newUserEmail,
                            password: _newUserPassword,
                          );

                          // ログインに成功した場合
                          // チャット画面に遷移＋ログイン画面を破棄
                          // ignore: use_build_context_synchronously, unnecessary_null_comparison
                          User? user = result.user;
                          final uuid = user?.uid;

                          // Email確認が済んでいる場合は、Home画面へ遷移
                          if (result.user!.emailVerified) {
                            // ignore: use_build_context_synchronously
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return ShiftCalendar(user_id: uuid);
                            }));
                          } else {
                            // print('NG');
                            setState(() {
                              _btn_click_num++;
                              _nocheckText =
                                  "まだメール確認が完了していません。\n確認メール内のリンクをクリックしてください。";
                            });
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            print(e.toString());
                          }
                        } finally {
                          endLoading();
                        }
                      },
                    ),
                  ),
                  // ignore: prefer_const_constructors
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                    // ignore: prefer_const_constructors
                    child: Text(
                      '※メールが届かない場合は、迷惑メールにフィルタリングされていないかご確認ください',
                      style: const TextStyle(color: Colors.black54),
                    ),
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
            ],
          );
        }),
      ),
    );
  }
}
