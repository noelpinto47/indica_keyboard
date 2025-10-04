
import 'indica_keyboard_platform_interface.dart';
export 'src/widgets/multilingual_keyboard.dart';
export 'src/models/keyboard_layout.dart';
export 'src/constants/keyboard_constants.dart';

class IndicaKeyboard {
  Future<String?> getPlatformVersion() {
    return IndicaKeyboardPlatform.instance.getPlatformVersion();
  }
}
