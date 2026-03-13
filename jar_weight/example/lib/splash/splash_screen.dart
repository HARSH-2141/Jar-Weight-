import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jar_weight_example/home_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void initState() {
    super.initState();
    WakelockPlus.enable();
    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(child: Lottie.asset('assets/animations/splash_lottie.json')),
    );
  }
}
