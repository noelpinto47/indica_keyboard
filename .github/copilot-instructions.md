# Indica Keyboard - AI Agent Instructions

## Project Overview
**Indica Keyboard** is a high-performance Flutter plugin providing multilingual keyboard support (English, Hindi, Marathi) with native Android/iOS optimization. The architecture uses native platform channels for 3-5x performance gains with automatic Dart fallback.

## Architecture & Data Flow

### Core Components
1. **`lib/src/widgets/multilingual_keyboard.dart`** - Main keyboard widget (~1500 lines)
   - Single stateful widget `IndicaKeyboard` handles all UI and state
   - Hybrid state management: `ValueNotifier` for granular updates (shift, conjunct mode, layout page) + `setState` for full keyboard changes (language switch, auto-capitalization)
   - Direct keyboard input flow: Key press → `_onKeyPress()` → Native service or Dart fallback → TextController update

2. **Native Platform Integration** (Android priority)
   - Android: `OptimizedIndicaTextProcessor.kt` with LRU caches (512 conjunct, 256 char, 128 delete), object pooling, and batch processing
   - iOS: `IndicaKeyboardPlugin.swift` (basic support, native optimization planned)
   - Flutter bridge: `lib/src/services/indica_native_service.dart` with automatic fallback
   - Communication: MethodChannel `'indica_keyboard'` for async native calls

3. **Layout System**
   - Static layouts cached in `lib/src/models/keyboard_layout.dart`
   - Multi-page support: Hindi/Marathi have 4 pages (basic consonants → conjuncts → advanced conjuncts → numbers/symbols)
   - Dynamic top row: Context-aware vowel attachments (matraas) based on selected consonant

4. **Typography System (v1.2.0+)**
   - **Font Asset**: `assets/fonts/NotoSansDevanagari-VariableFont_wdth,wght.ttf`
   - **Font Constant**: `KeyboardConstants.devanagariFont = 'NotoSansDevanagari'`
   - **Helper Method**: `_getTextStyleForLanguage()` automatically selects font based on `_currentLanguage`
   - **Platform Integration**:
     - Flutter: Declared in `pubspec.yaml` under `fonts` section
     - Android: Copied to `android/src/main/res/font/noto_sans_devanagari.ttf`
     - iOS: Included in `ios/Assets/` and referenced in `indica_keyboard.podspec`
   - **Usage Pattern**: All `TextStyle` instances use `fontFamily` and `package: 'indica_keyboard'` for Hindi/Marathi

### Critical State Management Patterns
- **DO use `ValueNotifier`** for localized UI updates: shift key appearance, conjunct button state, page indicators
- **DO use `setState`** for changes affecting entire keyboard: language switching, auto-capitalization state, layout page changes
- **DO NOT cache display logic** that depends on real-time state - call methods directly (e.g., `_shouldCapitalizeCached()` for shift icon)
- **Always sync ValueNotifier and state variables** together (see `_resetConjunctMode()` pattern: set `_conjunctMode = false` then `_conjunctModeNotifier.value = false`)

### Font Integration Pattern
When adding text that needs Devanagari support:
```dart
Text(
  displayText,
  style: _getTextStyleForLanguage(
    fontSize,
    fontWeight: FontWeight.normal,
    color: textColor,
  ),
)
```
The helper automatically applies:
- `fontFamily: 'NotoSansDevanagari'` for Hindi/Marathi
- `package: 'indica_keyboard'` for proper font resolution
- `null` for English (uses system default)

### Performance Optimization Strategy
1. Pre-load all language layouts in `initState()` - zero runtime loading
2. Cache keyboard height calculation (40% landscape limit with expandable keys)
3. Use `RepaintBoundary` on individual keys for 60fps rendering
4. Native processing: Check `IndicaNativeService.initialize()` → measure with `getProcessingStats()`
5. Font rendering optimized with variable font technology (single file, multiple weights)

## Language-Specific Features

### English (`'en'`)
- 3-state shift: `off` → `single` → `capsLock` (double-tap within 300ms)
- Auto-capitalization: Triggers at text start or after `[.!?]\\s+` regex match
- Shift icon paths: `caps-lock-enabled.svg` (single/auto-cap), `caps-lock-hold.svg` (caps lock), `default-caps-lock-off.svg` (off)
- Font: System default

### Hindi/Marathi (`'hi'`/`'mr'`)
- **Conjunct formation**: Press `+` button → select second consonant → creates conjunct (क + त = क्त)
- Conjunct state machine: `_conjunctMode` boolean + `_pendingConsonant` string + `_conjunctModeNotifier`
- **Critical bug pattern**: Always update `_conjunctModeNotifier.value` in async methods (`_handleConjunctFormation`, `_processConjunctConsonant`)
- Layout pages: 0 (consonants), 1 (common conjuncts), 2 (advanced conjuncts), 3 (numbers/symbols)
- Unicode ranges: Devanagari consonants `0x0915-0x0939`, matraas `0x093E-0x094C`, halant (virama) `0x094D`
- **Font**: Noto Sans Devanagari (variable font supporting all Devanagari Unicode ranges)

## Developer Workflows

### Testing & Building
```bash
# Run all tests (no native calls in test environment)
flutter test

# Build example app (tests keyboard integration)
cd example && flutter run

# Dry run for publishing
flutter pub publish --dry-run

# Performance benchmarking
# Run example app → tap speed icon → see native vs Dart metrics
```

### Font Updates (v1.2.0 workflow)
```bash
# 1. Add font to assets/fonts/
cp new-font.ttf assets/fonts/

# 2. Update pubspec.yaml fonts section
# 3. Copy to Android res/font/ (lowercase_with_underscores.ttf)
cp assets/fonts/NewFont.ttf android/src/main/res/font/new_font.ttf

# 4. Copy to iOS Assets/
cp assets/fonts/NewFont.ttf ios/Assets/

# 5. Update KeyboardConstants.devanagariFont constant
# 6. Run flutter pub get
flutter pub get
```

### Native Development (Android)
```bash
# Navigate to Android native code
cd android/src/main/kotlin/com/noelpinto47/indica_keyboard/

# Key files:
# - IndicaKeyboardPlugin.kt: MethodChannel handlers
# - OptimizedIndicaTextProcessor.kt: LRU caches, batch processing
```

### Version Release Process (from CHANGELOG.md pattern)
1. Update `version:` in `pubspec.yaml` (use semantic versioning)
2. Update `s.version` in `ios/indica_keyboard.podspec`
3. Update `CHANGELOG.md` with emoji-prefixed entries: 🚀 MAJOR, 🔧 FIXED, ⚡ PERFORMANCE, ✨ ENHANCED, 📱 IMPROVED
4. Update version references in `README.md` (installation section)
5. Run `flutter pub publish --dry-run` (expect 0 warnings)
6. Run `flutter test` (all tests must pass)
7. Commit changes with descriptive message
8. Create git tag: `git tag v1.x.x`
9. Push with tags: `git push origin main --tags`
10. Publish with `flutter pub publish`

## Common Bug Patterns & Fixes

### Auto-Capitalization Display Bugs
- **Symptom**: Keyboard shows lowercase but outputs uppercase (or vice versa)
- **Root cause**: Cached `_shouldCapitalize` not invalidating on text changes
- **Fix**: Call `_cachedShouldCapitalize = null` when text/state changes, use direct method calls for display

### Conjunct Button Not Deactivating
- **Symptom**: `+` button stays highlighted after conjunct formation
- **Root cause**: Missing `_conjunctModeNotifier.value = false` in async completion
- **Fix pattern**:
  ```dart
  Future<void> _handleConjunctFormation() async {
    // ... async native processing ...
    _conjunctMode = false;
    _conjunctModeNotifier.value = false; // MUST update notifier
    setState(() {}); // Optional: if other state changed
  }
  ```

### Layout Page Not Switching
- **Root cause**: Forgot to update `_layoutPageNotifier.value` after changing `_currentLayoutPage`
- **Fix**: Always pair: `_currentLayoutPage = newPage; _layoutPageNotifier.value = newPage;`

### Font Not Rendering (v1.2.0+)
- **Symptom**: Devanagari text shows in system font instead of Noto Sans
- **Common causes**:
  1. Forgot `package: 'indica_keyboard'` in TextStyle
  2. Font file not in `assets/fonts/` or wrong filename in pubspec.yaml
  3. Didn't run `flutter pub get` after adding font
  4. Wrong font family name (check exact spelling in pubspec.yaml)
- **Fix**: Use `_getTextStyleForLanguage()` helper method which handles all font logic automatically

## Project-Specific Conventions

### Naming
- Private methods: `_camelCase` (e.g., `_onKeyPress`, `_handleTextInput`)
- ValueNotifiers: `_<state>Notifier` suffix (e.g., `_shiftStateNotifier`, `_conjunctModeNotifier`)
- Cache variables: `_cached<Property>` prefix (e.g., `_cachedKeyboardHeight`)
- Font constants: `<script>Font` format (e.g., `devanagariFont`)

### Performance Comments
- Use `🚀 PERFORMANCE:` prefix for optimization-related comments
- Document cache invalidation: `// Invalidate layout cache`
- Mark ValueNotifier usage: `// 🚀 PERFORMANCE: Use ValueNotifier for granular updates`

### Constants Organization
- UI constants: `lib/src/constants/keyboard_constants.dart` (colors, dimensions, **fonts**)
- Performance tuning: `lib/src/constants/performance_constants.dart` (cache sizes, timeouts)
- Layout data: `lib/src/models/keyboard_layout.dart` (static keyboard layouts)

### Widget Builder Pattern
All key builders follow this pattern:
```dart
Widget _buildSomeKey() {
  return ValueListenableBuilder<StateType>(
    valueListenable: _someStateNotifier,
    builder: (context, stateValue, child) {
      return /* ... key UI using stateValue ... */;
    },
  );
}
```

## Integration Examples

### Basic Integration (from README.md)
```dart
IndicaKeyboard(
  supportedLanguages: const ['en', 'hi', 'mr'],
  textController: _textController,
  onLanguageChanged: (lang) => setState(() => _currentLanguage = lang),
  enableHapticFeedback: true,
)
```

### External Language Control (v1.0.1 feature)
```dart
// App controls language, keyboard follows
IndicaKeyboard(
  currentLanguage: _appLanguageState, // Pass external state
  onLanguageChanged: (lang) => setState(() => _appLanguageState = lang),
  // ...
)
```

### Using Custom Font in App (v1.2.0 feature)
```dart
// In your app's TextField to match keyboard font
TextField(
  style: TextStyle(
    fontSize: 18,
    fontFamily: (_currentLanguage == 'hi' || _currentLanguage == 'mr') 
        ? 'NotoSansDevanagari' 
        : null,
    package: (_currentLanguage == 'hi' || _currentLanguage == 'mr') 
        ? 'indica_keyboard' 
        : null,
  ),
)
```

## Key Files Reference
- Main widget: `lib/src/widgets/multilingual_keyboard.dart`
- Native service: `lib/src/services/indica_native_service.dart`
- Android native: `android/src/main/kotlin/.../OptimizedIndicaTextProcessor.kt`
- Layout definitions: `lib/src/models/keyboard_layout.dart`
- **Font asset**: `assets/fonts/NotoSansDevanagari-VariableFont_wdth,wght.ttf`
- **Font constant**: `lib/src/constants/keyboard_constants.dart` → `devanagariFont`
- Example app: `example/lib/main.dart`
- Performance benchmarks: `example/lib/performance_benchmark.dart`

## Version History Highlights
- **v1.2.0**: Noto Sans Devanagari font integration for enhanced typography
- **v1.1.1**: Conjunct mode visual state fix
- **v1.1.0**: Performance revolution with ValueNotifier system
- **v1.0.1**: External language control parameter
- **v1.0.0**: Production release with native optimization
- **v0.1.0**: Native Android integration
