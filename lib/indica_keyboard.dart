
import 'indica_keyboard_platform_interface.dart';

class IndicaKeyboard {
  Future<String?> getPlatformVersion() {
    return IndicaKeyboardPlatform.instance.getPlatformVersion();
  }
}
