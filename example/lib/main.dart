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
      title: 'Indica Keyboard Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
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
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showKeyboard = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: const Text(
            'Indica Keyboard Demo',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Language: ${_getLanguageName(_currentLanguage)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              // Text input field
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
                  keyboardType: TextInputType.none, // Disable system keyboard
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Clear button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _textController.clear();
                  },
                  child: const Text('Clear Text'),
                ),
              ),
            ],
          ),
        ),
        
        // Show Indica Keyboard when text field is focused
        bottomSheet: _showKeyboard
            ? IndicaKeyboard(
                supportedLanguages: const ['en', 'hi', 'mr'],
                initialLanguage: 'en',
                textController: _textController,
                onLanguageChanged: (language) {
                  setState(() {
                    _currentLanguage = language;
                  });
                },
                showLanguageSwitcher: true,
                enableHapticFeedback: true,
                primaryColor: Colors.red,
              )
            : null,
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी (Hindi)';
      case 'mr':
        return 'मराठी (Marathi)';
      default:
        return code.toUpperCase();
    }
  }
}
