# Indica Keyboard Plugin

A comprehensive multilingual keyboard plugin for Flutter that supports English, Hindi, and Marathi with intelligent text input capabilities.

## Features

- **Multi-language Support**: English, Hindi (Devanagari), and Marathi (Devanagari)
- **Conjunct Consonant Formation**: Advanced '+' button for creating complex Devanagari conjuncts
- **Integrated Focus Management**: Built-in TextField and focus handling - no setup required
- **Smart Text Input**: Intelligent vowel attachments and cursor-aware text processing
- **Dynamic Layouts**: Context-sensitive keyboard layouts with multiple pages for complex scripts
- **Customizable UI**: Theming support with custom colors and styling
- **Haptic Feedback**: Optional tactile feedback for enhanced user experience
- **Shift States**: Three-state shift functionality for English (off, single, caps lock)
- **Ultra-Simple Integration**: Complete keyboard solution in just 3 lines of code

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  indica_keyboard: ^0.0.2
```

## Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:indica_keyboard/indica_keyboard.dart';

class MyKeyboardApp extends StatefulWidget {
  @override
  _MyKeyboardAppState createState() => _MyKeyboardAppState();
}

class _MyKeyboardAppState extends State<MyKeyboardApp> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(hintText: 'Start typing...'),
              keyboardType: TextInputType.none, // Prevent system keyboard
            ),
          ),
          IndicaKeyboard(
            supportedLanguages: ['en', 'hi', 'mr'],
            textController: _textController, // Pass the controller directly
            onLanguageChanged: (language) {
              print('Language changed to: $language');
            },
          ),
        ],
      ),
    );
  }
}
```

## Advanced Usage

### Custom Styling

```dart
IndicaKeyboard(
  supportedLanguages: ['en', 'hi', 'mr'],
  textController: _textController,
  backgroundColor: Colors.grey[100],
  keyColor: Colors.white,
  textColor: Colors.black,
  primaryColor: Colors.blue,
  height: 300,
  enableHapticFeedback: true,
  showLanguageSwitcher: true,
)
```

## Supported Languages

### English (en)
- Standard QWERTY layout
- Three-state shift functionality (off, single, caps lock)
- Numbers and symbols

### Hindi (hi) - हिंदी
- Devanagari script with 4 layout pages
- Smart vowel attachments (matraas)
- **Conjunct consonants formation** with '+' button (क + त = क्त)
- Dynamic top row based on selected consonant

### Marathi (mr) - मराठी
- Devanagari script with Marathi-specific characters
- Support for ळ (La) and other Marathi-specific letters
- **Conjunct consonants formation** with '+' button
- 4 layout pages with comprehensive character coverage
- Smart text composition

## Advanced Features

### Conjunct Consonant Formation

For Hindi and Marathi, you can create conjunct consonants using the '+' button:

1. **Type first consonant**: क (ka)
2. **Press '+' button**: Button highlights, conjunct mode ON
3. **Type second consonant**: त (ta)  
4. **Result**: क्त (kta) - conjunct formed automatically

**Examples**:
- क + [+] + र = क्र (kra) - as in "क्रम"
- स + [+] + त = स्त (sta) - as in "मस्त"  
- न + [+] + य = न्य (nya) - as in "पुन्य"

**Toggle Mode**: Press '+' again to turn OFF conjunct mode if activated accidentally.

## API Reference

### MultilingualKeyboard

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `supportedLanguages` | `List<String>` | Required | List of language codes |
| `initialLanguage` | `String` | `'en'` | Initial language to display |
| `onTextInput` | `Function(String)?` | `null` | Callback for text input |
| `onLanguageChanged` | `Function(String)?` | `null` | Callback for language changes |
| `height` | `double?` | `null` | Custom keyboard height |
| `backgroundColor` | `Color?` | `null` | Custom background color |
| `keyColor` | `Color?` | `null` | Custom key color |
| `textColor` | `Color?` | `null` | Custom text color |
| `showLanguageSwitcher` | `bool` | `true` | Show language switcher button |
| `enableHapticFeedback` | `bool` | `true` | Enable haptic feedback |

## Smart Features

### Vowel Attachments (Hindi/Marathi)
When you select a consonant (like क), the top row dynamically shows vowel attachments:
- क (ka) → का (kaa), कि (ki), की (kii), कु (ku), कू (kuu), etc.

### Conjunct Consonants
Multiple layout pages provide access to complex conjunct consonants:
- क्ष (ksh), ज्ञ (gya), त्र (tra), श्र (shra)

## License

This project is licensed under the MIT License.ard

A new Flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

