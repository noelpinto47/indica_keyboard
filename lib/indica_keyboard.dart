
import 'indica_keyboard_platform_interface.dart';
export 'src/widgets/multilingual_keyboard.dart' show IndicaKeyboard;
export 'src/models/keyboard_layout.dart';
export 'src/constants/keyboard_constants.dart';
export 'src/services/indica_native_service.dart';

class IndicaKeyboardPlugin {
  Future<String?> getPlatformVersion() {
    return IndicaKeyboardPlatform.instance.getPlatformVersion();
  }
}
