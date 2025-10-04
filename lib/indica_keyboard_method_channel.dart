import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'indica_keyboard_platform_interface.dart';

/// An implementation of [IndicaKeyboardPlatform] that uses method channels.
class MethodChannelIndicaKeyboard extends IndicaKeyboardPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('indica_keyboard');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
