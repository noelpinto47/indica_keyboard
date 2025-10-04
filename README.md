# Indica Keyboard Plugin

A comprehensive multilingual keyboard plugin for Flutter that supports English, Hindi, and Marathi with intelligent text input capabilities.

## Features

- **Multi-language Support**: English, Hindi (Devanagari), and Marathi (Devanagari)
- **Smart Text Input**: Intelligent vowel attachments and conjunct consonants for Indic scripts
- **Dynamic Layouts**: Context-sensitive keyboard layouts with multiple pages for complex scripts
- **Customizable UI**: Theming support with custom colors and styling
- **Haptic Feedback**: Optional tactile feedback for enhanced user experience
- **Shift States**: Three-state shift functionality for English (off, single, caps lock)
- **Easy Integration**: Drop-in widget that can be added to any Flutter app

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  indica_keyboard: ^0.0.1
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

  void _handleTextInput(String text) {
    if (text == '⌫') {
      // Handle backspace
      if (_textController.text.isNotEmpty) {
        final currentText = _textController.text;
        _textController.text = currentText.substring(0, currentText.length - 1);
      }
    } else {
      // Handle regular text input
      _textController.text += text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(hintText: 'Start typing...'),
            ),
          ),
          MultilingualKeyboard(
            supportedLanguages: ['en', 'hi', 'mr'],
            onTextInput: _handleTextInput,
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
MultilingualKeyboard(
  supportedLanguages: ['en', 'hi', 'mr'],
  onTextInput: _handleTextInput,
  backgroundColor: Colors.grey[100],
  keyColor: Colors.white,
  textColor: Colors.black,
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
- Conjunct consonants and ligatures
- Dynamic top row based on selected consonant

### Marathi (mr) - मराठी
- Devanagari script with Marathi-specific characters
- Support for ळ (La) and other Marathi-specific letters
- 4 layout pages with comprehensive character coverage
- Smart text composition

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

