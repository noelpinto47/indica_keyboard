
import 'indica_keyboard_platform_interface.dart';
export 'src/widgets/multilingual_keyboard.dart' show IndicaKeyboard, IndicaKeyboardField;
export 'src/models/keyboard_layout.dart';
export 'src/constants/keyboard_constants.dart';

class IndicaKeyboardPlugin {
  Future<String?> getPlatformVersion() {
    return IndicaKeyboardPlatform.instance.getPlatformVersion();
  }
}
