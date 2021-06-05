import 'dart:io';
import 'package:agent/models/models.dart';
import 'package:agent/models/server.dart';
import 'package:agent/models/transaction.dart';
import 'package:agent/pages/confirm.dart';
import 'package:agent/pages/scan.dart';
import 'package:agent/pages/server_list.dart';
import 'package:agent/store/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:agent/pages/analytics.dart';
import 'package:agent/pages/home.dart';
import 'package:agent/pages/settings.dart';
import 'package:agent/styles/colors.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

import 'package:flutter_zoekits/flutter_zoekits.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';

void main() {
  if (Platform.isAndroid) {
    // 设置Android头部的导航栏透明
    SystemUiOverlayStyle systemUiOverlayStyle =
        SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

   @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state.toString());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: can I register splash to router?
    
    return SplashView(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ModelFactory().servr),
          ChangeNotifierProvider(create: (_) => ModelFactory().trans),
        ],
        builder: (context, child) => MaterialApp(
          title: "易付",
          theme: ThemeData(
            primaryColor: Colours.primaryColor,
          ),
          initialRoute: "/",
          onGenerateRoute: buildRouteGenerater({
            "/": ZRouter((context) => HomePage()),
            "/servers": ZRouter((context) => ServerListPage()),
            "/settings": ZRouter((context) => SettingsPage()),
            "/analytics": ZRouter((context) => AnalyticsPage()),
            "/confirm": ZRouter((context) => ConfirmPage()),
            "/scan": ZRouter((context) => ScanPage()),
          }),
        ),
      ),
      // build the splash
      builder: (context) => Image.asset("assets/logos/main.png", width: 50, height: 50).centered().box.white.make(),
      initItems: [
        DBProvider.instance.database,
        ModelFactory.instance.init(),
        Future.delayed(Duration(seconds: 1)),
      ],
    );
  }
}