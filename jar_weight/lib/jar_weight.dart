import 'dart:async';
import 'package:flutter/services.dart';

class JarWeight {
  static const MethodChannel _methodChannel = MethodChannel(
    'jar_weight/method',
  );
  static const EventChannel _eventChannel = EventChannel('jar_weight/scan');

  // 👇 1. ADD THIS MEMORY VARIABLE
  static bool isDeviceConnected = false;

  static Stream<dynamic> get scanStream =>
      _eventChannel.receiveBroadcastStream();

  static Future<List<Map<dynamic, dynamic>>> getPairedDevices() async {
    final List<dynamic>? devices = await _methodChannel.invokeMethod(
      'getPairedDevices',
    );
    return devices?.cast<Map<dynamic, dynamic>>() ?? [];
  }

  static Future<void> startScan() async =>
      await _methodChannel.invokeMethod('startScan');

  static Future<bool> pairDevice(String address) async {
    final bool? success = await _methodChannel.invokeMethod('pairDevice', {
      'address': address,
    });
    return success ?? false;
  }

  static Future<void> startServer() async =>
      await _methodChannel.invokeMethod('startServer');

  // 👇 2. UPDATE THIS FUNCTION TO CHANGE THE MEMORY TO TRUE
  static Future<void> connectToDevice(String address) async {
    await _methodChannel.invokeMethod('connectToDevice', {
      'address': address,
    });
    isDeviceConnected = true; // App will remember it is connected!
  }

  // 👇 ADD THIS NEW FUNCTION TO DISCONNECT
  static Future<void> disconnect() async {
    try {
      // 1. Tell the native Android/iOS code to drop the connection
      await _methodChannel.invokeMethod('disconnect');

      // 2. Update the memory variable
      isDeviceConnected = false;
    } catch (e) {
      print("Error disconnecting: $e");
    }
  }

  static Future<void> sendMessage(String message) async =>
      await _methodChannel.invokeMethod('sendMessage', {'message': message});
}