import 'package:flutter_test/flutter_test.dart';
import 'package:jar_weight/jar_weight.dart';
import 'package:jar_weight/jar_weight_platform_interface.dart';
import 'package:jar_weight/jar_weight_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockJarWeightPlatform
    with MockPlatformInterfaceMixin
    implements JarWeightPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final JarWeightPlatform initialPlatform = JarWeightPlatform.instance;

  test('$MethodChannelJarWeight is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelJarWeight>());
  });

  test('getPlatformVersion', () async {
    JarWeight jarWeightPlugin = JarWeight();
    MockJarWeightPlatform fakePlatform = MockJarWeightPlatform();
    JarWeightPlatform.instance = fakePlatform;

    expect(await jarWeightPlugin.getPlatformVersion(), '42');
  });
}
