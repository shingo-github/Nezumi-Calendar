// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nezumi_calendar/login_page.dart';

class ShiftPattern extends StatelessWidget {
  const ShiftPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // スプラッシュ画面などに書き換えても良い
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData) {
            // User が null でなない、つまりサインイン済みのホーム画面へ
            return const TimePicker(
              title: 'Shift Pattern Setting',
            );
          }
          // User が null である、つまり未サインインのサインイン画面へ
          return const LoginPage();
        },
      ),
    );
  }
}

class TimePicker extends StatefulWidget {
  // 後述の[TimePickerController]が必須パラメータです。[TimePickerController]経由で日時の操作・取得を行います。
  const TimePicker({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _TimePickerState createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  // ignore: prefer_const_constructors
  final List<String> _shiftPattern = [];
  late var timechangeflg = false;
  bool hayabtnflg = false;
  bool osobtnflg = false;
  bool nichibtnflg = false;
  bool yakinbtnflg = false;
  bool akebtnflg = false;
  bool isLoading = false;

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

  // 選択した日時を格納する変数
  // ignore: unnecessary_new
  List<DateTime> _hayatime = [
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 09, 00),
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 18, 00)
  ];
  // ignore: unnecessary_new
  List<DateTime> _osotime = [
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 11, 00),
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 20, 00)
  ];
  // ignore: unnecessary_new
  List<DateTime> _nichitime = [
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 08, 00),
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 17, 00)
  ];
  // ignore: unnecessary_new
  List<DateTime> _yakintime = [
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 17, 00),
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 25, 00)
  ];
  // ignore: unnecessary_new
  List<DateTime> _aketime = [
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 24, 00),
    // ignore: unnecessary_new
    new DateTime.utc(2025, 12, 31, 08, 00)
  ];

  // 日時を指定したフォーマットで指定するためのフォーマッター
  // ignore: unnecessary_new
  var formatter = new DateFormat('HH:mm');

  @override
  void initState() {
    final auth = FirebaseAuth.instance;
    // ignore: unused_local_variable
    final uid = auth.currentUser?.uid.toString();
    super.initState();
    // ignore: unused_label
    child:
    FirebaseFirestore.instance
        .collection('shift-pattern-$uid')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      // ignore: avoid_function_literals_in_foreach_calls
      snapshot.docs.forEach((doc) async {
        try {
          final shiftId = doc.id;
          DocumentSnapshot snapshot = await FirebaseFirestore.instance
              .collection('shift-pattern-$uid')
              .doc(shiftId)
              .get();
          List<String> shiftList = [
            snapshot.data().toString(),
          ];
          if (_shiftPattern.isNotEmpty) {
            // ignore: avoid_init_to_null
            Iterable<String>? existenceCheck = null;
            final keymodule = shiftList[0].split(':');
            final shiftkey = keymodule[0].replaceFirst('{', '');

            existenceCheck =
                _shiftPattern.where((element) => element.contains(shiftkey));
            if (existenceCheck.isNotEmpty) {
              final delstr = existenceCheck.toString();
              final delstrGeneration =
                  delstr.replaceFirst('(', '').replaceFirst(')', '');
              final delindex = _shiftPattern.indexOf(delstrGeneration);
              if (delindex >= 0) {
                _shiftPattern.removeAt(delindex);
              }
            }
          }
          if (mounted) {
            setState(() {
              return _shiftPattern.addAll(shiftList);
            });
          }
        } catch (e) {
          if (kDebugMode) {
            print('Something really unknown: $e');
          }
        }

        /// 取得したドキュメントIDのフィールド値memoの値を取得する
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    // ignore: unused_local_variable
    final uid = auth.currentUser?.uid.toString();
    if (_shiftPattern.isNotEmpty && timechangeflg == false) {
      for (var i = 0; i < _shiftPattern.length; i++) {
        var pattern = _shiftPattern.elementAt(i);

        // ignore: unnecessary_null_comparison, avoid_print
        if (pattern.contains('haya')) {
          final _getshifttime =
              GetShiftTime()._buildGetShiftTime(_shiftPattern, pattern)!;
          _hayatime = _getshifttime;
        }
        if (pattern.contains('oso')) {
          final _getshifttime =
              GetShiftTime()._buildGetShiftTime(_shiftPattern, pattern)!;
          _osotime = _getshifttime;
        }
        if (pattern.contains('nichi')) {
          final _getshifttime =
              GetShiftTime()._buildGetShiftTime(_shiftPattern, pattern)!;
          _nichitime = _getshifttime;
        }
        if (pattern.contains('yakin')) {
          final _getshifttime =
              GetShiftTime()._buildGetShiftTime(_shiftPattern, pattern)!;
          _yakintime = _getshifttime;
        }
        if (pattern.contains('ake')) {
          final _getshifttime =
              GetShiftTime()._buildGetShiftTime(_shiftPattern, pattern)!;
          _aketime = _getshifttime;
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Builder(builder: (context) {
        return Stack(children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const Text(
                      '早番 ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 231, 212, 45),
                      ),
                    ),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_hayatime[0]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              print(formatter.format(date));
                            }
                            hayabtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _hayatime[0] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _hayatime[0],
                              //DateTime.utc(2022, 4, 1, hayastaHH, hayastamm),
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    const Text('ー'),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_hayatime[1]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              // ignore: prefer_interpolation_to_compose_strings
                              print('change $date in time zone ' +
                                  date.timeZoneOffset.inHours.toString());
                            }
                            hayabtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _hayatime[1] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _hayatime[1],
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    // ignore: unused_local_variable

                    ElevatedButton(
                      onPressed: hayabtnflg == false
                          ? null
                          : () async {
                              try {
                                startLoading();
                                // ignore: avoid_init_to_null, unused_local_variable
                                Iterable<String>? existenceCheck = null;
                                existenceCheck = _shiftPattern.where(
                                    (element) => element.contains('haya'));
                                if (existenceCheck.isEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection(
                                          'shift-pattern-$uid') // コレクション指定
                                      .add({
                                    'haya':
                                        '${formatter.format(_hayatime[0])} - ${formatter.format(_hayatime[1])}',
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('早番の時間を設定しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                } else {
                                  GetId()
                                      ._buildGetId(existenceCheck, uid)
                                      .then((_docshiftList) async {
                                    await FirebaseFirestore.instance
                                        .collection('shift-pattern-$uid')
                                        .doc(_docshiftList) // コレクションID指定
                                        .update({
                                      'haya':
                                          '${formatter.format(_hayatime[0])} - ${formatter.format(_hayatime[1])}',
                                    });
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('早番の時間を更新しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                }
                                setState(() {
                                  hayabtnflg = false;
                                });
                              } catch (e) {
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              } finally {
                                endLoading();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            const Color.fromARGB(255, 248, 159, 239),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('登録'),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 2,
                thickness: 3,
                color: Colors.grey,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const Text(
                      '遅番 ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_osotime[0]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              print(formatter.format(date));
                            }
                            osobtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _osotime[0] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _osotime[0],
                              //DateTime.utc(2022, 4, 1, hayastaHH, hayastamm),
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    const Text('ー'),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_osotime[1]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              // ignore: prefer_interpolation_to_compose_strings
                              print('change $date in time zone ' +
                                  date.timeZoneOffset.inHours.toString());
                            }
                            osobtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _osotime[1] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _osotime[1],
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    // ignore: unused_local_variable

                    ElevatedButton(
                      onPressed: osobtnflg == false
                          ? null
                          : () async {
                              try {
                                startLoading();
                                // ignore: avoid_init_to_null, unused_local_variable
                                Iterable<String>? existenceCheck = null;
                                existenceCheck = _shiftPattern.where(
                                    (element) => element.contains('oso'));
                                if (existenceCheck.isEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection(
                                          'shift-pattern-$uid') // コレクション指定
                                      .add({
                                    'oso':
                                        '${formatter.format(_osotime[0])} - ${formatter.format(_osotime[1])}',
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('遅番の時間を設定しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                } else {
                                  GetId()
                                      ._buildGetId(existenceCheck, uid)
                                      .then((_docshiftList) async {
                                    await FirebaseFirestore.instance
                                        .collection('shift-pattern-$uid')
                                        .doc(_docshiftList) // コレクションID指定
                                        .update({
                                      'oso':
                                          '${formatter.format(_osotime[0])} - ${formatter.format(_osotime[1])}',
                                    });
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('遅番の時間を更新しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                }
                                setState(() {
                                  osobtnflg = false;
                                });
                              } catch (e) {
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              } finally {
                                endLoading();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            const Color.fromARGB(255, 248, 159, 239),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('登録'),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 2,
                thickness: 3,
                color: Colors.grey,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const Text(
                      '日勤 ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_nichitime[0]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              print(formatter.format(date));
                            }
                            nichibtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _nichitime[0] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _nichitime[0],
                              //DateTime.utc(2022, 4, 1, hayastaHH, hayastamm),
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    const Text('ー'),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_nichitime[1]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              // ignore: prefer_interpolation_to_compose_strings
                              print('change $date in time zone ' +
                                  date.timeZoneOffset.inHours.toString());
                            }
                            nichibtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _nichitime[1] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _nichitime[1],
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    // ignore: unused_local_variable

                    ElevatedButton(
                      onPressed: nichibtnflg == false
                          ? null
                          : () async {
                              try {
                                startLoading();
                                // ignore: avoid_init_to_null, unused_local_variable
                                Iterable<String>? existenceCheck = null;
                                existenceCheck = _shiftPattern.where(
                                    (element) => element.contains('nichi'));
                                if (existenceCheck.isEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection(
                                          'shift-pattern-$uid') // コレクション指定
                                      .add({
                                    'nichi':
                                        '${formatter.format(_nichitime[0])} - ${formatter.format(_nichitime[1])}',
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('日勤の時間を設定しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                } else {
                                  GetId()
                                      ._buildGetId(existenceCheck, uid)
                                      .then((_docshiftList) async {
                                    await FirebaseFirestore.instance
                                        .collection('shift-pattern-$uid')
                                        .doc(_docshiftList) // コレクションID指定
                                        .update({
                                      'nichi':
                                          '${formatter.format(_nichitime[0])} - ${formatter.format(_nichitime[1])}',
                                    });
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('日勤の時間を更新しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                }
                                setState(() {
                                  nichibtnflg = false;
                                });
                              } catch (e) {
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              } finally {
                                endLoading();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            const Color.fromARGB(255, 248, 159, 239),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('登録'),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 2,
                thickness: 3,
                color: Colors.grey,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const Text(
                      '夜勤 ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.purple,
                      ),
                    ),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_yakintime[0]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              print(formatter.format(date));
                            }
                            yakinbtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _yakintime[0] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _yakintime[0],
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    const Text('ー'),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_yakintime[1]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              // ignore: prefer_interpolation_to_compose_strings
                              print('change $date in time zone ' +
                                  date.timeZoneOffset.inHours.toString());
                            }
                            yakinbtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _yakintime[1] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _yakintime[1],
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    // ignore: unused_local_variable

                    ElevatedButton(
                      onPressed: yakinbtnflg == false
                          ? null
                          : () async {
                              try {
                                startLoading();
                                // ignore: avoid_init_to_null, unused_local_variable
                                Iterable<String>? existenceCheck = null;
                                existenceCheck = _shiftPattern.where(
                                    (element) => element.contains('yakin'));
                                if (existenceCheck.isEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection(
                                          'shift-pattern-$uid') // コレクション指定
                                      .add({
                                    'yakin':
                                        '${formatter.format(_yakintime[0])} - ${formatter.format(_yakintime[1])}',
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('夜勤の時間を設定しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                } else {
                                  GetId()
                                      ._buildGetId(existenceCheck, uid)
                                      .then((_docshiftList) async {
                                    await FirebaseFirestore.instance
                                        .collection('shift-pattern-$uid')
                                        .doc(_docshiftList) // コレクションID指定
                                        .update({
                                      'yakin':
                                          '${formatter.format(_yakintime[0])} - ${formatter.format(_yakintime[1])}',
                                    });
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('夜勤の時間を更新しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                }
                                setState(() {
                                  yakinbtnflg = false;
                                });
                              } catch (e) {
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              } finally {
                                endLoading();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            const Color.fromARGB(255, 248, 159, 239),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('登録'),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 2,
                thickness: 3,
                color: Colors.grey,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const Text(
                      '明け ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.brown,
                      ),
                    ),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_aketime[0]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              print(formatter.format(date));
                            }
                            akebtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _aketime[0] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _aketime[0],
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    const Text('ー'),
                    GestureDetector(
                        child: Text(
                          // フォーマッターを使用して指定したフォーマットで日時を表示
                          // format()に渡すのはDate型の値で、String型で返される
                          formatter.format(_aketime[1]),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        onTap: () {
                          DatePicker.showTime12hPicker(context,
                              showTitleActions: true,

                              // onChanged内の処理はDatepickerの選択に応じて毎回呼び出される
                              onChanged: (date) {
                            if (kDebugMode) {
                              // ignore: prefer_interpolation_to_compose_strings
                              print('change $date in time zone ' +
                                  date.timeZoneOffset.inHours.toString());
                            }
                            akebtnflg = true;
                          },
                              // onConfirm内の処理はDatepickerで選択完了後に呼び出される
                              onConfirm: (date) {
                            if (mounted) {
                              setState(() {
                                _aketime[1] = date;
                                timechangeflg = true;
                              });
                            }
                          },
                              // Datepickerのデフォルトで表示する日時
                              currentTime: _aketime[1],
                              // localによって色々な言語に対応
                              locale: LocaleType.jp);
                        }),
                    // ignore: unused_local_variable

                    ElevatedButton(
                      onPressed: akebtnflg == false
                          ? null
                          : () async {
                              try {
                                startLoading();
                                // ignore: avoid_init_to_null, unused_local_variable
                                Iterable<String>? existenceCheck = null;
                                existenceCheck = _shiftPattern.where(
                                    (element) => element.contains('ake'));
                                if (existenceCheck.isEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection(
                                          'shift-pattern-$uid') // コレクション指定
                                      .add({
                                    'ake':
                                        '${formatter.format(_aketime[0])} - ${formatter.format(_aketime[1])}',
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('明けの時間を設定しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                } else {
                                  GetId()
                                      ._buildGetId(existenceCheck, uid)
                                      .then((_docshiftList) async {
                                    await FirebaseFirestore.instance
                                        .collection('shift-pattern-$uid')
                                        .doc(_docshiftList) // コレクションID指定
                                        .update({
                                      'ake':
                                          '${formatter.format(_aketime[0])} - ${formatter.format(_aketime[1])}',
                                    });
                                  });
                                  // ignore: use_build_context_synchronously
                                  // ignore: prefer_const_constructors, use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('明けの時間を更新しました'),
                                    backgroundColor:
                                        Color.fromARGB(255, 248, 159, 239),
                                  ));
                                }
                                setState(() {
                                  akebtnflg = false;
                                });
                              } catch (e) {
                                if (kDebugMode) {
                                  // ignore: unnecessary_string_interpolations
                                  print("${e.toString()}");
                                }
                              } finally {
                                endLoading();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            const Color.fromARGB(255, 248, 159, 239),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('登録'),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 2,
                thickness: 3,
                color: Colors.grey,
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
    );
  }
}

// [TimePicker]と同じファイルに記述します
class GetShiftTime {
  List<DateTime> _getshifttime = [
    DateTime.utc(2025, 12, 31, 00, 00),
    DateTime.utc(2025, 12, 31, 00, 00)
  ];
  // ignore: unused_element
  List<DateTime>? _buildGetShiftTime(_shiftPattern, String pattern) {
    final strlist = pattern.split(' ');
    List firstHH = strlist[1].split(':');
    List lastHH = strlist[3].split(':');

    int firstH = int.parse(firstHH[0]);
    int firstm = int.parse(firstHH[1]);
    int lastH = int.parse(lastHH[0]);
    int lastm = int.parse(lastHH[1].replaceFirst('}', ''));
    _getshifttime = [
      DateTime.utc(2025, 12, 31, firstH, firstm),
      DateTime.utc(2025, 12, 31, lastH, lastm)
    ];
    return _getshifttime;
  }
}

class GetId {
  Future<String> _buildGetId(existenceCheck, uid) async {
    List docshiftList = [];
    final shiftmodule = existenceCheck.first;
    final keymodule = shiftmodule.split(':');
    final shiftkey = keymodule[0].replaceFirst('{', '');
    final valmodule = shiftmodule.split('{$shiftkey: ');
    final shiftval = valmodule[1].replaceFirst('}', '');

    await FirebaseFirestore.instance
        .collection('shift-pattern-$uid')
        .where(shiftkey, isEqualTo: shiftval)
        .get()
        .then(
          (QuerySnapshot querySnapshot) => {
            // ignore: avoid_function_literals_in_foreach_calls
            querySnapshot.docs.forEach(
              (doc) {
                return docshiftList.add(doc.id);
              },
            ),
          },
        );
    String _docshiftList = docshiftList.first.toString();
    return _docshiftList;
    //_docshiftList;
  }
}
