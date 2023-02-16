// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nezumi_calendar/login_page.dart';
import 'package:nezumi_calendar/main.dart';
import 'package:nezumi_calendar/shift_pattern.dart';
// ignore: unused_import
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';

class ShiftCalendar extends StatelessWidget {
  // ignore: non_constant_identifier_names
  const ShiftCalendar({super.key, required user_id});

  @override
  Widget build(BuildContext context) {
    // ignore: prefer_const_constructors
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // スプラッシュ画面などに書き換えても良い
            return const SizedBox();
          }
          if (snapshot.hasData) {
            // User が null でなない、つまりサインイン済みのホーム画面へ
            return const ShiftCalendarPage(
              title: 'カレンダー',
              user_id: '',
            );
          }
          // User が null である、つまり未サインインのサインイン画面へ
          return const LoginPage();
        },
      ),
    );
  }
}

class ShiftCalendarPage extends StatefulWidget {
  // ignore: non_constant_identifier_names
  final String user_id;
  const ShiftCalendarPage(
      // ignore: non_constant_identifier_names
      {Key? key,
      required this.title,
      // ignore: non_constant_identifier_names
      required this.user_id})
      : super(key: key);

  final String title;

  @override
  State<ShiftCalendarPage> createState() => _ShiftCalendarPageState();
}

// ignore: duplicate_ignore,
class _ShiftCalendarPageState extends State<ShiftCalendarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _focused =
      DateTime.parse(DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc()));

  // ignore: unnecessary_nullable_for_final_variable_declarations
  final List<String>? _messageText = [];
  final List<String> _shiftPattern = [];
  final Map<DateTime, List> _eventsList = {};
  final Map<DateTime, List> _shiftList = {};
  final String uid = '';
  final List<Iterable> _daysList = [];

  // シフト時間デフォ値
  // ignore: prefer_final_fields
  late String? _hayaresult = '9:00 - 18:00';
  // ignore: prefer_final_fields, unused_field
  late String? _osoresult = '11:00 - 20:00';
  // ignore: prefer_final_fields, unused_field
  late String? _nichiresult = '8:00 - 17:00';
  // ignore: prefer_final_fields, unused_field
  late String? _yakinresult = '17:00 - 25:00';
  // ignore: prefer_final_fields, unused_field
  late String? _akeresult = '24:00 - 8:00';
  // シフトボタンクリック判定フラグ
  late String shiftbtnflg = '';

  bool btnflg = true;
  // ignore: unused_field
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selected;

  bool isLoading = false;

  void startLoading() {
    setState(() {
      isLoading = true;
    });
  }

  void endLoading() {
    setState(() {
      isLoading = false;
    });
  }

  // DateTime型から20210930の8桁のint型へ変換
  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  @override
  void initState() {
    final auth = FirebaseAuth.instance;
    // ignore:
    final uid = auth.currentUser?.uid.toString();
    super.initState();

    // ignore: unused_label
    child:
    _selected = _focused;
    FirebaseFirestore.instance
        .collection('schedule-$uid')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      // ignore: avoid_function_literals_in_foreach_calls
      snapshot.docs.forEach((doc) {
        /// 取得したドキュメントIDのフィールド値memoの値を取得する
        Map<DateTime, List> sellMap = {
          DateTime.parse(doc.get('daytimekey')): doc.get('memo')
        };
        if (mounted) {
          setState(() {
            return _eventsList.addAll(sellMap);
          });
        }
      });
    });
    FirebaseFirestore.instance
        .collection('shift-schedule-$uid')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      // ignore: avoid_function_literals_in_foreach_calls
      snapshot.docs.forEach((doc) {
        /// 取得したドキュメントIDのフィールド値memoの値を取得する
        Map<DateTime, List> shiftMap = {
          DateTime.parse(doc.get('daytimekey')): doc.get('shift'),
        };
        if (mounted) {
          setState(() {
            return _shiftList.addAll(shiftMap);
          });
        }
      });
    });
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
          // ignore: avoid_init_to_null,
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

  bool def = true;
  bool isShow = false;
  // ignore: non_constant_identifier_names
  bool WigetShow() {
    return isShow = false;
  }

// ignore: prefer_typing_uninitialized_variables
  var hayapattern;
  // ignore: duplicate_ignore,
  @override
  // ignore: duplicate_ignore,
  Widget build(BuildContext context) {
    //画面のサイズを取得する
    final size = MediaQuery.of(context).size;
    //高さを取得する
    final height = size.height;
    //幅を取得する
    final width = size.width;
    final auth = FirebaseAuth.instance;
    // ignore:
    final uid = auth.currentUser?.uid.toString();

    // ignore: prefer_typing_uninitialized_variables
    if (_messageText!.length > 1) {
      _messageText!.removeRange(1, _messageText!.length);
    }
    if (_messageText!.contains('')) {
      _messageText?.clear();
    }

    // ignore: no_leading_underscores_for_local_identifiers
    final _form = GlobalKey<FormState>();

    final dateFormatForDayOfWeek = DateFormat.E('ja');
    final formatStrForDayOfWeek =
        dateFormatForDayOfWeek.format(DateTime.parse(_selected.toString()));
    // ignore: no_leading_underscores_for_local_identifiers
    final _events = LinkedHashMap<DateTime, List>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(_eventsList);
    DateTime result = DateTime(_selected!.year, _selected!.month + 1, 1)
        .add(const Duration(days: -1));
    // ignore: no_leading_underscores_for_local_identifiers
    var _editController = TextEditingController();
    List getEvent(DateTime day) {
      return _events[day] ?? [];
    }

    // ignore: no_leading_underscores_for_local_identifiers
    Color _textColor(DateTime day) {
      // ignore: no_leading_underscores_for_local_identifiers
      const _defaultTextColor = Colors.black87;

      if (day.weekday == DateTime.sunday) {
        return Colors.red;
      }
      if (day.weekday == DateTime.saturday) {
        return Colors.blue[600]!;
      }
      return _defaultTextColor;
    }

    // ignore:
    final Iterable<Text> editController = getEvent(_selected!)
        .map((event) => Text(_editController.text = event))
        .toList();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 248, 159, 239),
              ),
              child: Text(
                'Calendar Menu',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
              ),
              title: const Text('カレンダー'),
              onTap: () {
                if (mounted) {
                  setState(WigetShow);
                }
                if (mounted) {
                  setState(
                    () => def = true,
                  );
                }

                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_calendar,
              ),
              title: const Text('シフト入力'),
              onTap: () {
                if (mounted) {
                  setState(
                    () => def = false,
                  );
                }
                if (mounted) {
                  setState(
                    () => isShow = true,
                  );
                }
                _selected =
                    DateTime.parse(DateFormat('yyyy-MM-01').format(_selected!));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text('ログアウト'),
              onTap: () async {
                try {
                  startLoading();
                  // ログアウト処理
                  // 内部で保持しているログイン情報等が初期化される
                  await FirebaseAuth.instance.signOut();
                  // ログイン画面に遷移
                  // ignore: use_build_context_synchronously
                  await Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) {
                      return const MyApp();
                    }),
                  );
                } catch (e) {
                  if (kDebugMode) {
                    print('Something really unknown: $e');
                  }
                } finally {
                  endLoading();
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Builder(builder: (context) {
          return Stack(
            children: [
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 35),
                  ),
                  Stack(children: [
                    TableCalendar<dynamic>(
                      locale: 'ja_JP',
                      firstDay: DateTime.utc(2022, 4, 1),
                      lastDay: DateTime.utc(2025, 12, 31),
                      focusedDay: _focused,
                      //日付のウィジェットの高さ

                      rowHeight: height / 2 * 0.17,
                      daysOfWeekHeight: height * 0.05,

                      eventLoader: getEvent, //追記
                      selectedDayPredicate: (day) {
                        return isSameDay(_selected, day);
                      },
                      onDaySelected: (selected, focused) {
                        if (!isSameDay(_selected, selected)) {
                          if (mounted) {
                            setState(() {
                              _selected = DateTime.parse(
                                  DateFormat('yyyy-MM-dd').format(selected));
                              _focused = focused;
                            });
                          }
                        }
                      },

                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        leftChevronVisible: false,
                        rightChevronVisible: false, //weekのボタン表示なし
                      ),

                      calendarBuilders: CalendarBuilders(
                        // ignore: no_leading_underscores_for_local_identifiers
                        markerBuilder:
                            // ignore: no_leading_underscores_for_local_identifiers
                            (BuildContext context, DateTime day, _events) {
                          // イベント、シフト両方ある場合
                          if (_events.isNotEmpty &&
                              (_shiftList.containsKey(
                                      DateTime(day.year, day.month, day.day)
                                          .toLocal()) ==
                                  true)) {
                            return Stack(children: [
                              ListView.builder(
                                  padding: const EdgeInsets.only(top: 28),
                                  itemCount:
                                      _events.length, //List(List名).length
                                  // ignore: no_leading_underscores_for_local_identifiers
                                  itemBuilder: (BuildContext context, _events) {
                                    return SizedBox(
                                      height: height / 20,
                                      child: _events == 0
                                          ? _buildEventsMarker(day, _shiftList)
                                          : null,
                                    );
                                  }),
                              Positioned(
                                right: 5,
                                bottom: height < 700 ? 43 : 57,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red[300],
                                  ),
                                  width: 8.0,
                                  height: 8.0,
                                ),
                              ),
                            ]);
                          }
                          // イベントのみがある場合
                          if (_events.isNotEmpty &&
                              (_shiftList.containsKey(
                                      DateTime(day.year, day.month, day.day)
                                          .toLocal()) ==
                                  false)) {
                            return Stack(children: [
                              Positioned(
                                right: 5,
                                bottom: height < 700 ? 43 : 57,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red[300],
                                  ),
                                  width: 8.0,
                                  height: 8.0,
                                ),
                              ),
                            ]);
                          }
                          // シフトのみがある場合
                          if ((_events.isEmpty == true) &&
                              (_shiftList.containsKey(
                                      DateTime(day.year, day.month, day.day)) ==
                                  true)) {
                            //print(_shiftList.containsKey(day.toLocal()));
                            return Stack(children: [
                              ListView.builder(
                                  padding: const EdgeInsets.only(top: 28),
                                  //List(List名).length
                                  // ignore: no_leading_underscores_for_local_identifiers
                                  itemBuilder: (BuildContext context, _events) {
                                    return SizedBox(
                                      height: height / 20,
                                      child: _events == 0
                                          ? _buildEventsMarker(
                                              day.toLocal(), _shiftList)
                                          : null,
                                    );
                                  }),
                            ]);
                          }
                          return null;
                        },
                        dowBuilder: (context, day) {
                          if (day.weekday == DateTime.sunday) {
                            final text = DateFormat.E("ja").format(day);
                            return Center(
                              child: Text(
                                text,
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }
                          if (day.weekday == DateTime.saturday) {
                            final text = DateFormat.E("ja").format(day);

                            return Center(
                              child: Text(
                                text,
                                style: const TextStyle(color: Colors.blue),
                              ),
                            );
                          }
                          return null;
                        },
                        defaultBuilder: (BuildContext context, DateTime day,
                            DateTime focusedDay) {
                          return AnimatedContainer(
                            height: 200,
                            duration: const Duration(milliseconds: 250),
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[600]!,
                                width: 0.3,
                              ),
                            ),
                            alignment: Alignment.topCenter,
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: _textColor(day),
                              ),
                            ),
                          );
                        },
                        outsideBuilder: (BuildContext context, DateTime day,
                            DateTime focusedDay) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[600]!,
                                width: 0.3,
                              ),
                            ),
                            alignment: Alignment.topCenter,
                            child: Text(
                              day.day.toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                        // ignore: no_leading_underscores_for_local_identifiers
                        todayBuilder: (context, date, _events) => Container(
                            margin: const EdgeInsets.all(0.0),
                            alignment: Alignment.topCenter,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 248, 159, 239),
                            ),
                            child: Text(
                              date.day.toString(),
                              style: const TextStyle(color: Colors.white),
                            )),
                        selectedBuilder: (BuildContext context, DateTime day,
                            DateTime focusedDay) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color.fromARGB(255, 248, 159, 239),
                                width: 3.0,
                              ),
                            ),
                            alignment: Alignment.topCenter,
                            child: Text(
                              day.day.toString(),
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                    ),
                  ]),
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '${DateFormat(" y年 M月 d日 ").format(DateTime.parse(_selected.toString()))}($formatStrForDayOfWeek)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Builder(
                        builder: (BuildContext context) {
                          return Container(
                              child: _buildEventsShift(_shiftList, _selected));
                        },
                      ),
                    ],
                  ),

                  Visibility(
                    visible: def,
                    child: TextFormField(
                      readOnly: true,
                      controller: _editController,
                      maxLines: 6,
                      minLines: 6,
                      onChanged: (value) {
                        _editController = value as TextEditingController;
                      },
                      onTap: () async {
                        _messageText!.removeRange(0, _messageText!.length);
                        //登録
                        if (_editController.text == "") {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled:
                                true, //trueにしないと、Containerのheightが反映されない
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15)),
                            ),
                            builder: (BuildContext context) {
                              return SizedBox(
                                  height: 600,
                                  // モーダル展開後のTextFormField
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            '${DateFormat(" y年 M月 d日 ").format(DateTime.parse(_selected.toString()))}($formatStrForDayOfWeek)',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Builder(
                                            builder: (BuildContext context) {
                                              return Container(
                                                  child: _buildEventsShift(
                                                      _shiftList, _selected));
                                            },
                                          ),
                                        ],
                                      ),
                                      TextFormField(
                                        textInputAction: TextInputAction.next,
                                        key: _form,
                                        autofocus: true,
                                        controller: _editController,
                                        maxLines: 6,
                                        minLines: 6,
                                        maxLengthEnforcement:
                                            MaxLengthEnforcement.none,
                                        onChanged: (String value) {
                                          if (mounted) {
                                            setState(() {
                                              String? messageText = value;
                                              if (messageText.isNotEmpty) {
                                                return _messageText?.insertAll(
                                                    0, [messageText]);
                                              }
                                            });
                                          }
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(0),
                                            borderSide: const BorderSide(
                                              width: 2,
                                              color: Color.fromARGB(
                                                  255, 248, 159, 239),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(0),
                                            borderSide: const BorderSide(
                                              width: 2,
                                              color: Color.fromARGB(
                                                  255, 248, 159, 239),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Builder(builder: (context) {
                                        return SizedBox(
                                            width: 150, //横幅
                                            height: 40, //高さ
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 248, 159, 239),
                                                shape: const StadiumBorder(),
                                              ),
                                              onPressed: () async {
                                                if (_messageText!.isNotEmpty) {
                                                  primaryFocus?.unfocus();
                                                  // ignore: use_build_context_synchronously
                                                  Navigator.of(context).pop();

                                                  try {
                                                    startLoading();
                                                    // 投稿メッセージ用ドキュメント作成
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'schedule-$uid') // コレクションID指定
                                                        .add({
                                                      'daytimekey':
                                                          _selected.toString(),
                                                      'memo': _messageText
                                                    });
                                                    // 1つ前の画面に戻る
                                                  } catch (e) {
                                                    if (kDebugMode) {
                                                      print(
                                                          'Something really unknown: $e');
                                                    }
                                                  } finally {
                                                    endLoading();
                                                  }
                                                } else {
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: const Text('登録'),
                                            ));
                                      }),
                                    ],
                                  ));
                            },
                          );

                          //更新・削除
                        } else if (_editController.text != "") {
                          //ドキュメントID取得
                          List docList = [];

                          await FirebaseFirestore.instance
                              .collection('schedule-$uid')
                              .where("daytimekey",
                                  isEqualTo: _selected.toString())
                              .get()
                              .then(
                                (QuerySnapshot querySnapshot) => {
                                  // ignore: avoid_function_literals_in_foreach_calls
                                  querySnapshot.docs.forEach(
                                    (doc) {
                                      return docList.add(doc.id);
                                    },
                                  ),
                                },
                              );
                          // ignore: no_leading_underscores_for_local_identifiers
                          String _docList = docList.first.toString();

                          // ignore: use_build_context_synchronously
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled:
                                true, //trueにしないと、Containerのheightが反映されない
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15)),
                            ),
                            builder: (BuildContext context) {
                              Future showConfirmDialog(BuildContext context) {
                                return showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) {
                                    return AlertDialog(
                                      content: const Text("内容を削除しますか？"),
                                      actions: [
                                        TextButton(
                                          child: const Text("いいえ"),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                        TextButton(
                                          child: const Text("はい"),
                                          onPressed: () async {
                                            Navigator.popUntil(context,
                                                (route) => route.isFirst);
                                            try {
                                              startLoading();
                                              // 投稿メッセージ用ドキュメント作成
                                              if (_messageText!.isEmpty) {
                                                FirebaseFirestore.instance
                                                    .collection('schedule-$uid')
                                                    .doc(_docList)
                                                    .delete();
                                              } else {
                                                FirebaseFirestore.instance
                                                    .collection('schedule-$uid')
                                                    .doc(_docList) // コレクションID指定
                                                    .delete();
                                              }
                                              if (mounted) {
                                                setState(() {
                                                  _eventsList.remove(_selected);
                                                });
                                              }
                                              // 1つ前の画面に戻る
                                            } catch (e) {
                                              if (kDebugMode) {
                                                print(
                                                    'Something really unknown: $e');
                                              }
                                            } finally {
                                              endLoading();
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }

                              if (_messageText!.contains('')) {
                                _messageText?.clear();
                              }
                              return SizedBox(
                                  height: 600,
                                  // モーダル展開後のTextFormField
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            '${DateFormat(" y年 M月 d日 ").format(DateTime.parse(_selected.toString()))}($formatStrForDayOfWeek)',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Builder(
                                            builder: (BuildContext context) {
                                              return Container(
                                                  child: _buildEventsShift(
                                                      _shiftList, _selected));
                                            },
                                          ),
                                        ],
                                      ),
                                      TextFormField(
                                        key: _form,
                                        autofocus: true,
                                        controller: _editController,
                                        maxLines: 6,
                                        minLines: 6,
                                        maxLengthEnforcement:
                                            MaxLengthEnforcement.none,
                                        onChanged: (String value) {
                                          if (mounted) {
                                            setState(() {
                                              String? messageText = value;
                                              return _messageText
                                                  ?.insertAll(0, [messageText]);
                                            });
                                          }
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(0),
                                            borderSide: const BorderSide(
                                              width: 2,
                                              color: Color.fromARGB(
                                                  255, 248, 159, 239),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(0),
                                            borderSide: const BorderSide(
                                              width: 2,
                                              color: Color.fromARGB(
                                                  255, 248, 159, 239),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // ignore: avoid_unnecessary_containers
                                      Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            SizedBox(
                                              width: 120, //横幅
                                              height: 45, //高さ
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 248, 159, 239),
                                                  shape: const StadiumBorder(),
                                                ),
                                                onPressed: _messageText!.isEmpty
                                                    ? null
                                                    : () async {
                                                        primaryFocus?.unfocus();
                                                        try {
                                                          startLoading();
                                                          // 投稿メッセージ用ドキュメント作成
                                                          if (_messageText!
                                                              .isEmpty) {
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'schedule-$uid')
                                                                .doc(_docList)
                                                                .delete();
                                                            if (mounted) {
                                                              setState(() {
                                                                _eventsList.remove(
                                                                    _selected);
                                                              });
                                                            }
                                                          } else {
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'schedule-$uid')
                                                                .doc(
                                                                    _docList) // コレクションID指定
                                                                .update({
                                                              'memo':
                                                                  _messageText,
                                                            });
                                                          }
                                                          // 1つ前の画面に戻る
                                                        } catch (e) {
                                                          if (kDebugMode) {
                                                            print(
                                                                'Something really unknown: $e');
                                                          }
                                                        } finally {
                                                          endLoading();
                                                          // ignore: use_build_context_synchronously
                                                          Navigator.of(context)
                                                              .pop();
                                                        }
                                                      },
                                                child: const Text('更新'),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 120, //横幅
                                              height: 45, //高さ
                                              child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    backgroundColor: Colors.red,
                                                    shape:
                                                        const StadiumBorder(),
                                                  ),
                                                  onPressed: () async {
                                                    await showConfirmDialog(
                                                        context);
                                                  },
                                                  child: const Text('削除')),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ));
                            },
                          );

                          return _messageText
                              ?.insertAll(0, [_editController.text]);
                        }

                        // ignore: use_build_context_synchronously
                      },
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: const BorderSide(
                            width: 2,
                            color: Color.fromARGB(255, 248, 159, 239),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: const BorderSide(
                            width: 2,
                            color: Color.fromARGB(255, 248, 159, 239),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Visibility(
                    visible: isShow,
                    child: Container(
                        padding: const EdgeInsets.all(10.10),
                        child: Wrap(
                          spacing: 20,
                          direction: Axis.horizontal, // 追加した。directionを指定
                          children: <Widget>[
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: btnflg == false
                                  ? null
                                  : () async {
                                      if (mounted) {
                                        setState(() {
                                          btnflg = false;
                                        });
                                      }
                                      if (_shiftList[_selected] == null) {
                                        // 末日を選択していたら次月へ遷移
                                        if (_selected == result) {
                                          _focused = DateTime(
                                            _selected!.year,
                                            _selected!.month + 1,
                                          );
                                        }
                                        // 追加
                                        await FirebaseFirestore.instance
                                            .collection(
                                                'shift-schedule-$uid') // コレクション指定
                                            .add({
                                          'daytimekey': _selected.toString(),
                                          'shift': [
                                            {'holiday': ''}
                                          ]
                                        });
                                        if (mounted) {
                                          setState(() {
                                            _selected = DateTime(
                                              _selected!.year,
                                              _selected!.month,
                                              _selected!.day + 1,
                                            );
                                          });
                                        }
                                      } else {
                                        // 更新
                                        GetId()
                                            ._buildGetId(_selected, uid)
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_docshiftList) async {
                                          await FirebaseFirestore.instance
                                              .collection('shift-schedule-$uid')
                                              .doc(_docshiftList) // コレクションID指定
                                              .update({
                                            'shift': [
                                              {'holiday': ''}
                                            ]
                                          });
                                          if (mounted) {
                                            setState(() {
                                              // 末日を選択していたら次月へ遷移
                                              if (_selected == result) {
                                                _focused = DateTime(
                                                  _selected!.year,
                                                  _selected!.month + 1,
                                                );
                                              }
                                              _selected = DateTime(
                                                _selected!.year,
                                                _selected!.month,
                                                _selected!.day + 1,
                                              );
                                            });
                                          }
                                        });
                                      }
                                      btnflg = true;
                                    },
                              child: const Text('休み'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    const Color.fromARGB(255, 231, 212, 45),
                                shape: const StadiumBorder(),
                                side: const BorderSide(
                                    color: Color.fromARGB(255, 231, 212, 45)),
                              ),
                              onPressed: btnflg == false
                                  ? null
                                  : () async {
                                      if (mounted) {
                                        setState(() {
                                          btnflg = false;
                                        });
                                      }
                                      shiftbtnflg = 'haya';
                                      if (_shiftList[_selected] == null) {
                                        // 末日を選択していたら次月へ遷移
                                        if (_selected == result) {
                                          _focused = DateTime(
                                            _selected!.year,
                                            _selected!.month + 1,
                                          );
                                        }
                                        // 追加
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_hayaresult) async {
                                          await FirebaseFirestore.instance
                                              .collection(
                                                  'shift-schedule-$uid') // コレクションID指定
                                              .add({
                                            'daytimekey': _selected.toString(),
                                            'shift': [
                                              {'haya': _hayaresult}
                                            ]
                                          });
                                          if (mounted) {
                                            setState(() {
                                              _selected = DateTime(
                                                _selected!.year,
                                                _selected!.month,
                                                _selected!.day + 1,
                                              );
                                              shiftbtnflg = 'haya';
                                            });
                                          }
                                        });
                                      } else {
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_hayaresult) async {
                                          // 更新
                                          GetId()
                                              ._buildGetId(_selected, uid)
                                              // ignore: no_leading_underscores_for_local_identifiers
                                              .then((_docshiftList) async {
                                            await FirebaseFirestore.instance
                                                .collection(
                                                    'shift-schedule-$uid')
                                                .doc(
                                                    _docshiftList) // コレクションID指定
                                                .update({
                                              'shift': [
                                                {'haya': _hayaresult}
                                              ]
                                            });
                                            if (mounted) {
                                              setState(() {
                                                // 末日を選択していたら次月へ遷移
                                                if (_selected == result) {
                                                  _focused = DateTime(
                                                    _selected!.year,
                                                    _selected!.month + 1,
                                                  );
                                                }
                                                _selected = DateTime(
                                                  _selected!.year,
                                                  _selected!.month,
                                                  _selected!.day + 1,
                                                );
                                                shiftbtnflg = 'haya';
                                              });
                                            }
                                          });
                                        });
                                      }
                                      btnflg = true;
                                    },
                              child: const Text('早番'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: Colors.green),
                              ),
                              onPressed: btnflg == false
                                  ? null
                                  : () async {
                                      if (mounted) {
                                        setState(() {
                                          btnflg = false;
                                        });
                                      }
                                      shiftbtnflg = 'oso';
                                      if (_shiftList[_selected] == null) {
                                        // 末日を選択していたら次月へ遷移
                                        if (_selected == result) {
                                          _focused = DateTime(
                                            _selected!.year,
                                            _selected!.month + 1,
                                          );
                                        }
                                        // 追加
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_osoresult) async {
                                          await FirebaseFirestore.instance
                                              .collection(
                                                  'shift-schedule-$uid') // コレクションID指定
                                              .add({
                                            'daytimekey': _selected.toString(),
                                            'shift': [
                                              {'oso': _osoresult}
                                            ]
                                          });
                                          if (mounted) {
                                            setState(() {
                                              _selected = DateTime(
                                                _selected!.year,
                                                _selected!.month,
                                                _selected!.day + 1,
                                              );
                                              shiftbtnflg = 'oso';
                                            });
                                          }
                                        });
                                      } else {
                                        // 更新
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_osoresult) async {
                                          GetId()
                                              ._buildGetId(_selected, uid)
                                              // ignore: no_leading_underscores_for_local_identifiers
                                              .then((_docshiftList) async {
                                            await FirebaseFirestore.instance
                                                .collection(
                                                    'shift-schedule-$uid')
                                                .doc(
                                                    _docshiftList) // コレクションID指定
                                                .update({
                                              'shift': [
                                                {'oso': _osoresult}
                                              ]
                                            });
                                            if (mounted) {
                                              setState(() {
                                                // 末日を選択していたら次月へ遷移
                                                if (_selected == result) {
                                                  _focused = DateTime(
                                                    _selected!.year,
                                                    _selected!.month + 1,
                                                  );
                                                }
                                                _selected = DateTime(
                                                  _selected!.year,
                                                  _selected!.month,
                                                  _selected!.day + 1,
                                                );
                                                shiftbtnflg = 'oso';
                                              });
                                            }
                                          });
                                        });
                                      }
                                      btnflg = true;
                                    },
                              child: const Text('遅番'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: Colors.blue),
                              ),
                              onPressed: btnflg == false
                                  ? null
                                  : () async {
                                      if (mounted) {
                                        setState(() {
                                          btnflg = false;
                                        });
                                      }
                                      shiftbtnflg = 'nichi';
                                      if (_shiftList[_selected] == null) {
                                        // 末日を選択していたら次月へ遷移
                                        if (_selected == result) {
                                          _focused = DateTime(
                                            _selected!.year,
                                            _selected!.month + 1,
                                          );
                                        }
                                        // 追加
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_nichiresult) async {
                                          await FirebaseFirestore.instance
                                              .collection(
                                                  'shift-schedule-$uid') // コレクションID指定
                                              .add({
                                            'daytimekey': _selected.toString(),
                                            'shift': [
                                              {'nichi': _nichiresult}
                                            ]
                                          });
                                          if (mounted) {
                                            setState(() {
                                              _selected = DateTime(
                                                _selected!.year,
                                                _selected!.month,
                                                _selected!.day + 1,
                                              );
                                              shiftbtnflg = 'nichi';
                                            });
                                          }
                                        });
                                      } else {
                                        // 更新
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_nichiresult) async {
                                          GetId()
                                              ._buildGetId(_selected, uid)
                                              // ignore: no_leading_underscores_for_local_identifiers
                                              .then((_docshiftList) async {
                                            await FirebaseFirestore.instance
                                                .collection(
                                                    'shift-schedule-$uid')
                                                .doc(
                                                    _docshiftList) // コレクションID指定
                                                .update({
                                              'shift': [
                                                {'nichi': _nichiresult}
                                              ]
                                            });
                                            if (mounted) {
                                              setState(() {
                                                // 末日を選択していたら次月へ遷移
                                                if (_selected == result) {
                                                  _focused = DateTime(
                                                    _selected!.year,
                                                    _selected!.month + 1,
                                                  );
                                                }
                                                _selected = DateTime(
                                                  _selected!.year,
                                                  _selected!.month,
                                                  _selected!.day + 1,
                                                );
                                                shiftbtnflg = 'nichi';
                                              });
                                            }
                                          });
                                        });
                                      }
                                      btnflg = true;
                                    },
                              child: const Text('日勤'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.purple,
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: Colors.purple),
                              ),
                              onPressed: btnflg == false
                                  ? null
                                  : () async {
                                      if (mounted) {
                                        setState(() {
                                          btnflg = false;
                                        });
                                      }
                                      shiftbtnflg = 'yakin';
                                      if (_shiftList[_selected] == null) {
                                        // 末日を選択していたら次月へ遷移
                                        if (_selected == result) {
                                          _focused = DateTime(
                                            _selected!.year,
                                            _selected!.month + 1,
                                          );
                                        }
                                        // 追加
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_yakinresult) async {
                                          await FirebaseFirestore.instance
                                              .collection(
                                                  'shift-schedule-$uid') // コレクションID指定
                                              .add({
                                            'daytimekey': _selected.toString(),
                                            'shift': [
                                              {'yakin': _yakinresult}
                                            ]
                                          });
                                          if (mounted) {
                                            setState(() {
                                              _selected = DateTime(
                                                _selected!.year,
                                                _selected!.month,
                                                _selected!.day + 1,
                                              );
                                              shiftbtnflg = 'yakin';
                                            });
                                          }
                                        });
                                      } else {
                                        // 更新
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_yakinresult) async {
                                          GetId()
                                              ._buildGetId(_selected, uid)
                                              // ignore: no_leading_underscores_for_local_identifiers
                                              .then((_docshiftList) async {
                                            await FirebaseFirestore.instance
                                                .collection(
                                                    'shift-schedule-$uid')
                                                .doc(
                                                    _docshiftList) // コレクションID指定
                                                .update({
                                              'shift': [
                                                {'yakin': _yakinresult}
                                              ]
                                            });
                                            if (mounted) {
                                              setState(() {
                                                // 末日を選択していたら次月へ遷移
                                                if (_selected == result) {
                                                  _focused = DateTime(
                                                    _selected!.year,
                                                    _selected!.month + 1,
                                                  );
                                                }
                                                _selected = DateTime(
                                                  _selected!.year,
                                                  _selected!.month,
                                                  _selected!.day + 1,
                                                );
                                                shiftbtnflg = 'yakin';
                                              });
                                            }
                                          });
                                        });
                                      }
                                      btnflg = true;
                                    },
                              child: const Text('夜勤'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.brown,
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: Colors.brown),
                              ),
                              onPressed: btnflg == false
                                  ? null
                                  : () async {
                                      if (mounted) {
                                        setState(() {
                                          btnflg = false;
                                        });
                                      }
                                      shiftbtnflg = 'ake';
                                      if (_shiftList[_selected] == null) {
                                        // 末日を選択していたら次月へ遷移
                                        if (_selected == result) {
                                          _focused = DateTime(
                                            _selected!.year,
                                            _selected!.month + 1,
                                          );
                                        }

                                        // 追加
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_akeresult) async {
                                          await FirebaseFirestore.instance
                                              .collection(
                                                  'shift-schedule-$uid') // コレクションID指定
                                              .add({
                                            'daytimekey': _selected.toString(),
                                            'shift': [
                                              {'ake': _akeresult}
                                            ]
                                          });
                                          if (mounted) {
                                            setState(() {
                                              _selected = DateTime(
                                                _selected!.year,
                                                _selected!.month,
                                                _selected!.day + 1,
                                              );
                                              shiftbtnflg = 'ake';
                                            });
                                          }
                                        });
                                      } else {
                                        // 更新
                                        GetShift()
                                            ._buildGetShift(
                                          _shiftPattern,
                                          _hayaresult,
                                          _osoresult,
                                          _nichiresult,
                                          _yakinresult,
                                          _akeresult,
                                          shiftbtnflg,
                                        )
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_akeresult) async {
                                          GetId()
                                              ._buildGetId(_selected, uid)
                                              // ignore: no_leading_underscores_for_local_identifiers
                                              .then((_docshiftList) async {
                                            await FirebaseFirestore.instance
                                                .collection(
                                                    'shift-schedule-$uid')
                                                .doc(
                                                    _docshiftList) // コレクションID指定
                                                .update({
                                              'shift': [
                                                {'ake': _akeresult}
                                              ]
                                            });
                                            if (mounted) {
                                              setState(() {
                                                // 末日を選択していたら次月へ遷移
                                                if (_selected == result) {
                                                  _focused = DateTime(
                                                    _selected!.year,
                                                    _selected!.month + 1,
                                                  );
                                                }
                                                _selected = DateTime(
                                                  _selected!.year,
                                                  _selected!.month,
                                                  _selected!.day + 1,
                                                );
                                                shiftbtnflg = 'ake';
                                              });
                                            }
                                          });
                                        });
                                      }
                                      btnflg = true;
                                    },
                              child: const Text('明け'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: Colors.black),
                              ),
                              onPressed: btnflg == false
                                  ? null
                                  : () async {
                                      if (mounted) {
                                        setState(() {
                                          btnflg = false;
                                        });
                                      }
                                      if (_shiftList[_selected] != null) {
                                        // 末日を選択していたら次月へ遷移
                                        if (_selected == result) {
                                          _focused = DateTime(
                                            _selected!.year,
                                            _selected!.month + 1,
                                          );
                                        }
                                        // 削除
                                        GetId()
                                            ._buildGetId(_selected, uid)
                                            // ignore: no_leading_underscores_for_local_identifiers
                                            .then((_docshiftList) async {
                                          await FirebaseFirestore.instance
                                              .collection('shift-schedule-$uid')
                                              .doc(_docshiftList) // コレクションID指定
                                              .delete();
                                          if (mounted) {
                                            setState(() {
                                              _shiftList.remove(_selected);
                                            });
                                          }
                                          // ignore: no_leading_underscores_for_local_identifiers
                                        }).then((_shiftList) {
                                          _selected = DateTime(
                                            _selected!.year,
                                            _selected!.month,
                                            _selected!.day + 1,
                                          );
                                          // 末日を選択していたら次月へ遷移
                                        });
                                      } else {
                                        if (mounted) {
                                          setState(() {
                                            // 末日を選択していたら次月へ遷移
                                            if (_selected == result) {
                                              _focused = DateTime(
                                                _selected!.year,
                                                _selected!.month + 1,
                                              );
                                            }
                                            _selected = DateTime(
                                              _selected!.year,
                                              _selected!.month,
                                              _selected!.day + 1,
                                            );
                                          });
                                        }
                                      }
                                      btnflg = true;
                                    },
                              child: const Text('　　'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                          secondaryAnimation) {
                                        return const ShiftPattern();
                                      },
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const Offset begin =
                                            Offset(1.0, 0.0); // 右から左
                                        // final Offset begin = Offset(-1.0, 0.0); // 左から右
                                        const Offset end = Offset.zero;
                                        final Animatable<Offset> tween =
                                            Tween(begin: begin, end: end).chain(
                                                CurveTween(
                                                    curve: Curves.easeInOut));
                                        final Animation<Offset>
                                            offsetAnimation =
                                            animation.drive(tween);
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: const Text('シフトパターン設定'),
                              ),
                            ),
                          ],
                        )),
                  ), //--------------------------------------------------------------------
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

// 各日付セルに返すWidget
// ignore: no_leading_underscores_for_local_identifiers
Widget? _buildEventsMarker(DateTime day, _shiftList) {
  final shiftListTime = _shiftList[DateTime(day.year, day.month, day.day)];

  final shifttime = shiftListTime[0];
  if (shifttime.containsKey('haya') == true) {
    return const Center(
      child: Text(
        '早番',
        style: TextStyle(
          fontSize: 18,
          color: Color.fromARGB(255, 231, 212, 45),
        ),
      ),
    );
  } else if (shifttime.containsKey('oso') == true) {
    return const Center(
      child: Text(
        '遅番',
        style: TextStyle(
          fontSize: 18,
          color: Colors.green,
        ),
      ),
    );
  } else if (shifttime.containsKey('holiday') == true) {
    return const Center(
      child: Text(
        '休み',
        style: TextStyle(
          fontSize: 18,
          color: Colors.red,
        ),
      ),
    );
  } else if (shifttime.containsKey('nichi') == true) {
    return const Center(
      child: Text(
        '日勤',
        style: TextStyle(
          fontSize: 18,
          color: Colors.blue,
        ),
      ),
    );
  } else if (shifttime.containsKey('yakin') == true) {
    return const Center(
      child: Text(
        '夜勤',
        style: TextStyle(
          fontSize: 18,
          color: Colors.purple,
        ),
      ),
    );
  } else if (shifttime.containsKey('ake') == true) {
    return const Center(
      child: Text(
        '明け',
        style: TextStyle(
          fontSize: 18,
          color: Colors.brown,
        ),
      ),
    );
  }
  return null;
}

// TextFormField上部に返すWidget
Widget? _buildEventsShift(shiftList, selected) {
  final selectshift = shiftList[selected];
  if (selectshift == null) {
    // ignore: avoid_unnecessary_containers
    return Container(
      child: const Text(''),
    );
  }
  final selectshifttime = selectshift[0];
  if (selectshifttime.containsKey('haya') == true) {
    final haya = selectshifttime['haya'];
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Text(
        // ignore: prefer_interpolation_to_compose_strings
        ' 早番 ' + haya,
        style: const TextStyle(
          fontSize: 17,
          color: Color.fromARGB(255, 231, 212, 45),
        ),
      ),
    );
  } else if (selectshifttime.containsKey('oso') == true) {
    final oso = selectshifttime['oso'];
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Text(
        // ignore: prefer_interpolation_to_compose_strings
        ' 遅番 ' + oso,
        style: const TextStyle(
          fontSize: 17,
          color: Colors.green,
        ),
      ),
    );
  } else if (selectshifttime.containsKey('holiday') == true) {
    // ignore: avoid_unnecessary_containers
    return Container(
      child: const Text(
        ' 休み ',
        style: TextStyle(
          fontSize: 17,
          color: Colors.red,
        ),
      ),
    );
  } else if (selectshifttime.containsKey('nichi') == true) {
    final nichi = selectshifttime['nichi'];
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Text(
        // ignore: prefer_interpolation_to_compose_strings
        ' 日勤 ' + nichi,
        style: const TextStyle(
          fontSize: 17,
          color: Colors.blue,
        ),
      ),
    );
  } else if (selectshifttime.containsKey('yakin') == true) {
    final yakin = selectshifttime['yakin'];
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Text(
        // ignore: prefer_interpolation_to_compose_strings
        ' 夜勤 ' + yakin,
        style: const TextStyle(
          fontSize: 17,
          color: Colors.purple,
        ),
      ),
    );
  } else if (selectshifttime.containsKey('ake') == true) {
    final ake = selectshifttime['ake'];
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Text(
        // ignore: prefer_interpolation_to_compose_strings
        ' 明け ' + ake,
        style: const TextStyle(
          fontSize: 17,
          color: Colors.brown,
        ),
      ),
    );
  }
  return null;
}

// 登録済みセルID取得Class
class GetId {
  // ignore: no_leading_underscores_for_local_identifiers
  Future<String> _buildGetId(_selected, uid) async {
    List docshiftList = [];

    await FirebaseFirestore.instance
        .collection('shift-schedule-$uid')
        .where("daytimekey", isEqualTo: _selected.toString())
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
    // ignore: no_leading_underscores_for_local_identifiers
    String _docshiftList = docshiftList.first.toString();
    return _docshiftList;
  }
}

class GetShift {
  // ignore: unused_element
  Future _buildGetShift(
    // ignore: no_leading_underscores_for_local_identifiers
    _shiftPattern,
    // ignore: no_leading_underscores_for_local_identifiers
    _hayaresult,
    // ignore: no_leading_underscores_for_local_identifiers
    _osoresult,
    // ignore: no_leading_underscores_for_local_identifiers
    _nichiresult,
    // ignore: no_leading_underscores_for_local_identifiers
    _yakinresult,
    // ignore: no_leading_underscores_for_local_identifiers
    _akeresult,
    shiftbtnflg,
  ) async {
    if (_shiftPattern.isNotEmpty) {
      for (var i = 0; i < _shiftPattern.length; i++) {
        var pattern = _shiftPattern.elementAt(i);
        if (pattern.contains('haya')) {
          if (shiftbtnflg == 'haya') {
            final strlist = pattern.split('haya:');
            return _hayaresult = strlist[1].replaceFirst('}', '');
          }
        } else if (pattern.contains('oso')) {
          if (shiftbtnflg == 'oso') {
            final strlist = pattern.split('oso:');
            return _osoresult = strlist[1].replaceFirst('}', '');
          }
        } else if (pattern.contains('nichi')) {
          if (shiftbtnflg == 'nichi') {
            final strlist = pattern.split('nichi:');
            return _nichiresult = strlist[1].replaceFirst('}', '');
          }
        } else if (pattern.contains('yakin')) {
          if (shiftbtnflg == 'yakin') {
            final strlist = pattern.split('yakin:');
            return _yakinresult = strlist[1].replaceFirst('}', '');
          }
        } else if (pattern.contains('ake')) {
          if (shiftbtnflg == 'ake') {
            final strlist = pattern.split('ake:');
            return _akeresult = strlist[1].replaceFirst('}', '');
          }
        }
      }
    } else {
      if (shiftbtnflg == 'haya') {
        return _hayaresult;
      } else if (shiftbtnflg == 'oso') {
        return _osoresult;
      } else if (shiftbtnflg == 'nichi') {
        return _nichiresult;
      } else if (shiftbtnflg == 'yakin') {
        return _yakinresult;
      } else if (shiftbtnflg == 'ake') {
        return _akeresult;
      }
    }
    if (shiftbtnflg == 'haya') {
      return _hayaresult;
    } else if (shiftbtnflg == 'oso') {
      return _osoresult;
    } else if (shiftbtnflg == 'nichi') {
      return _nichiresult;
    } else if (shiftbtnflg == 'yakin') {
      return _yakinresult;
    } else if (shiftbtnflg == 'ake') {
      return _akeresult;
    }
  }
}
