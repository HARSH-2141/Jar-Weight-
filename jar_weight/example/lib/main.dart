import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:jar_weight/jar_weight.dart';
import 'package:jar_weight_example/home_screen.dart';
import 'package:jar_weight_example/setting/alerts_expiry_screen.dart';
import 'package:jar_weight_example/setting/setting_screen.dart';
import 'package:jar_weight_example/splash/splash_screen.dart';

import 'jar/add_new_jar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
        '/add_new_jar': (context) => AddNewJar(),
        '/setting_screen' : (context) => SettingScreen(),
        '/alert_expiry': (context) => AlertsExpiryScreen(),
      },
    );
  }
}
