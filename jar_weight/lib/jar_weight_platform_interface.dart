import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'jar_weight_method_channel.dart';

abstract class JarWeightPlatform extends PlatformInterface {
  /// Constructs a JarWeightPlatform.
  JarWeightPlatform() : super(token: _token);

  static final Object _token = Object();

  static JarWeightPlatform _instance = MethodChannelJarWeight();

  /// The default instance of [JarWeightPlatform] to use.
  ///
  /// Defaults to [MethodChannelJarWeight].
  static JarWeightPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [JarWeightPlatform] when
  /// they register themselves.
  static set instance(JarWeightPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
