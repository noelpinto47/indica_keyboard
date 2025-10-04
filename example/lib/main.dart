import 'package:flutter/material.dart';
import 'package:indica_keyboard/indica_keyboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multilingual Keyboard Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const KeyboardDemoPage(),
    );
  }
}

class KeyboardDemoPage extends StatefulWidget {
  const KeyboardDemoPage({super.key});

  @override
  State<KeyboardDemoPage> createState() => _KeyboardDemoPageState();
}

class _KeyboardDemoPageState extends State<KeyboardDemoPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showKeyboard = false;
  bool _isDialogOpen = false; // Track dialog state
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showKeyboard = true;
        });
      } else {
        // Don't hide keyboard immediately on focus lost
        // This prevents keyboard from disappearing when dialogs open
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isDialogOpen && !_focusNode.hasFocus) {
            setState(() {
              _showKeyboard = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextInput(String text) {
    if (text == '⌫') {
      // Handle backspace
      if (_textController.text.isNotEmpty) {
        final currentText = _textController.text;
        final newText = currentText.substring(0, currentText.length - 1);
        _textController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    } else {
      // Handle regular text input
      final currentText = _textController.text;
      final selection = _textController.selection;
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      final newOffset = selection.start + text.length;
      
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
  }

  void _handleLanguageChanged(String language) {
    setState(() {
      _currentLanguage = language;
    });
  }

  void _handleDialogStateChanged(bool isOpen) {
    setState(() {
      _isDialogOpen = isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Multilingual Keyboard Demo'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Text input area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Language: ${_getLanguageName(_currentLanguage)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: 'Tap here to start typing...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: const TextStyle(fontSize: 18),
                      readOnly: true, // Prevent system keyboard
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _textController.clear();
                        },
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showKeyboard = !_showKeyboard;
                          });
                        },
                        child: Text(_showKeyboard ? 'Hide Keyboard' : 'Show Keyboard'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Multilingual keyboard
          if (_showKeyboard)
            MultilingualKeyboard(
              supportedLanguages: const ['en', 'hi', 'mr'],
              initialLanguage: 'en',
              onTextInput: _handleTextInput,
              onLanguageChanged: _handleLanguageChanged,
              onDialogStateChanged: _handleDialogStateChanged,
              showLanguageSwitcher: true,
              enableHapticFeedback: true,
              primaryColor: Colors.red, // Custom primary color
            ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'hi': return 'हिंदी (Hindi)';
      case 'mr': return 'मराठी (Marathi)';
      default: return code.toUpperCase();
    }
  }
}
