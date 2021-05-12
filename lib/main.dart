import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:messages/loading_widget.dart';
import 'package:messages/progress_button.dart';
import 'package:share/share.dart';
import 'package:workmanager/workmanager.dart';

import './helpers/db_helper.dart';
import 'aya.dart';
import 'helpers/share_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black, // navigation bar color
    statusBarColor: Colors.black, // status bar color
  ));
  WidgetsFlutterBinding.ensureInitialized();
  initialize();
  await Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask("1", "task",
      existingWorkPolicy: ExistingWorkPolicy.append,
      inputData: {'string': 'string'},
      initialDelay: Duration(seconds: 10),
      frequency: Duration(days: 1),
      constraints: Constraints(
          networkType: NetworkType.not_required, requiresDeviceIdle: false));
  runApp(MyApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    List<Aya> ayat = [];
    String aya = "";
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'no badge channel', 'no badge name', 'no badge description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      enableLights: true,
      icon: 'flower',
      styleInformation: BigTextStyleInformation(''),
// largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true);
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await DBHelper.getData('ayat')
        .then((dataList) => ayat = dataList.map((e) => Aya.fromMap(e)).toList())
        .then((value) {
      aya = ayat.length == 0
          ? "لم تقم باضافة اياتك بعد"
          : ayat[Random().nextInt(ayat.length)].aya;
    }).then((value) async {
      if (ayat.length > 0)
        await flutterLocalNotificationsPlugin.show(
          0,
          'رسالتك اليوم',
          aya,
          platformChannelSpecifics,
          payload: '',
        );
    });
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [Locale("ar", "EG")],
      title: 'رسائل قرآنيه',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'رسائل قرآنيه'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _form = GlobalKey<FormState>();
  List<Aya> ayat = [];
  int num = 0;
  bool add = false;
  bool show = false;
  bool loadingMsg = false;
  String editedText;
  String _sharedText;

  @override
  void initState() {
    super.initState();
    // scheduleNotification();
    ShareService()
      ..onDataReceived = _handleSharedData
      ..getSharedData().then(_handleSharedData);
  }

  void _handleSharedData(String sharedData) {
    if (sharedData.length > 4)
      setState(() {
        _sharedText = sharedData;
        show = false;
        add = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage("images/back.jpg"), fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 5,
          backgroundColor: Colors.black54,
          title: Text(
            'رسائل قرآنيه',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (add)
                Container(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 30, bottom: 30),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  // height: 300,
                  child: Form(
                      key: _form,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 10.0),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0)),
                              fillColor: Colors.white54,
                              filled: true,
                            ),
                            style: const TextStyle(color: Colors.black),
                            onSaved: (value) {
                              if (value.isNotEmpty) {
                                if (editedText == null) {
                                  String date = DateTime.now().toString();
                                  DBHelper.insert(
                                          'ayat', Aya(date: date, aya: value))
                                      .then((value) => _sharedText = null);
                                } else {
                                  String date = DateTime.now().toString();
                                  DBHelper.update(
                                          'ayat',
                                          Aya(
                                              date: date,
                                              aya: value,
                                              id: ayat[num].id))
                                      .then((value) => editedText = null);
                                }
                              }
                            },
                            maxLines: null,
                            cursorColor: Colors.black,
                            initialValue: editedText ?? _sharedText ?? null,
                          ),
                          ProgressButtonWidget(() async {
                            FocusScope.of(context).unfocus();
                            _form.currentState.save();
                            await Future.delayed(Duration(seconds: 1))
                                .then((value) {
                              if (mounted)
                                setState(() {
                                  show = false;
                                  add = false;
                                });
                            });
                          }),
                        ],
                      )),
                ),
              show
                  ? Container(
                      height: 450,
                      width: 400,
                      child: loadingMsg
                          ? Center(child: LoadingWidget())
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TweenAnimationBuilder(
                                  curve: Curves.ease,
                                  tween: Tween<double>(begin: 0, end: 400),
                                  duration: Duration(seconds: 4),
                                  builder: (BuildContext context, double size,
                                      Widget child) {
                                    return Container(
                                      height: size,
                                      width: size,
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 30),
                                    padding: const EdgeInsets.all(60),
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image:
                                                AssetImage("images/msgBox.png"),
                                            fit: BoxFit.fill)),
                                    // height:
                                    //     MediaQuery.of(context).size.height * .3,
                                    child: ayat.length == 0
                                        ? Center(
                                            child: Text(
                                              'لم تقم باضافة اياتك بعد',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : Center(
                                            child: SingleChildScrollView(
                                              child: Text(
                                                ayat[num].aya,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.fade,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                if (ayat.length > 0)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                          icon: Icon(
                                            Icons.share,
                                            color: Colors.teal,
                                            size: 30,
                                          ),
                                          onPressed: () {
                                            if (ayat.length != 0)
                                              Share.share(ayat[num].aya,
                                                  subject: 'رسائل قرأنيه');
                                          }),
                                      IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              editedText = ayat[num].aya;
                                              show = false;
                                              add = true;
                                            });
                                          }),
                                      IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 30,
                                          ),
                                          onPressed: () {
                                            DBHelper.delete(
                                                    'ayat', ayat[num].id)
                                                .then((value) {
                                              Fluttertoast.showToast(
                                                  msg: "تم حذف الآيه",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.BOTTOM,
                                                  timeInSecForIosWeb: 1,
                                                  backgroundColor: Colors.white,
                                                  textColor: Colors.black,
                                                  fontSize: 16.0);
                                              setState(() {
                                                show = false;
                                                add = false;
                                              });
                                            });
                                          }),
                                    ],
                                  )
                              ],
                            ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(
                          top: 100.0, right: 20, left: 20),
                      child: ElevatedButton(
                        style: ButtonStyle(
                            padding: MaterialStateProperty.all(
                                EdgeInsets.only(top: 15, bottom: 15)),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)))),
                        onPressed: showMsg,
                        child: Text(
                          'رساله',
                          style: const TextStyle(
                              color: Colors.black, fontSize: 30),
                        ),
                      ),
                    ),
              SizedBox(
                height: 20,
              ),
              if (!add)
                TextButton(
                  onPressed: () {
                    setState(() {
                      show = false;
                      add = true;
                    });
                  },
                  child: Text(
                    'إضافة آيه',
                    style: const TextStyle(color: Colors.white, fontSize: 30),
                  ),
                  // color: Colors.transparent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchAndSet() async {
    await DBHelper.getData('ayat').then(
        (dataList) => ayat = dataList.map((e) => Aya.fromMap(e)).toList());
  }

  Future showMsg() async {
    _sharedText = null;
    editedText = null;
    setState(() {
      loadingMsg = true;
      add = false;
      show = true;
    });
    await fetchAndSet().then((value) {
      num = ayat.length == 0 ? 0 : Random().nextInt(ayat.length);
      setState(() {
        loadingMsg = false;
      });
    });
  }

  // Future scheduleNotification() async {
  //   var androidPlatformChannelSpecifics = AndroidNotificationDetails(
  //     'no badge channel', 'no badge name', 'no badge description',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     ticker: 'ticker',
  //     enableLights: true,
  //     icon: 'flower',
  //     // largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
  //   );
  //   var iOSPlatformChannelSpecifics = IOSNotificationDetails(
  //       presentAlert: true, presentBadge: true, presentSound: true);
  //   var platformChannelSpecifics = NotificationDetails(
  //       android: androidPlatformChannelSpecifics,
  //       iOS: iOSPlatformChannelSpecifics);
  //   await flutterLocalNotificationsPlugin.periodicallyShow(
  //     0,
  //     '         رساله',
  //     null,
  //     RepeatInterval.daily,
  //     platformChannelSpecifics,
  //     androidAllowWhileIdle: true,
  //     payload: '',
  //   );
  // }
}

Future initialize() async {
  const initializationSettingsAndroid = AndroidInitializationSettings('flower');
  final initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {});
  final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  final notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    // await showMsg();
  }
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      // await showMsg();
    }
  });
}
