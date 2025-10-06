import 'package:flutter_test/flutter_test.dart';
import 'package:indica_keyboard/indica_keyboard.dart';
import 'package:indica_keyboard/indica_keyboard_platform_interface.dart';
import 'package:indica_keyboard/indica_keyboard_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIndicaKeyboardPlatform
    with MockPlatformInterfaceMixin
    implements IndicaKeyboardPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IndicaKeyboardPlatform initialPlatform = IndicaKeyboardPlatform.instance;

  test('$MethodChannelIndicaKeyboard is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIndicaKeyboard>());
  });

  test('getPlatformVersion', () async {
    IndicaKeyboardPlugin indicaKeyboardPlugin = IndicaKeyboardPlugin();
    MockIndicaKeyboardPlatform fakePlatform = MockIndicaKeyboardPlatform();
    IndicaKeyboardPlatform.instance = fakePlatform;

    expect(await indicaKeyboardPlugin.getPlatformVersion(), '42');
  });
}
