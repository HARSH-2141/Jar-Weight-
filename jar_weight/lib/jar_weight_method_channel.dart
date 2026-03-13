import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'jar_weight_platform_interface.dart';

/// An implementation of [JarWeightPlatform] that uses method channels.
class MethodChannelJarWeight extends JarWeightPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('jar_weight');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
