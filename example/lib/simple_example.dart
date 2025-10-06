import 'package:flutter/material.dart';
import 'package:indica_keyboard/indica_keyboard.dart';

void main() {
  runApp(const SimpleKeyboardApp());
}

class SimpleKeyboardApp extends StatelessWidget {
  const SimpleKeyboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Indica Keyboard Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SimpleKeyboardPage(),
    );
  }
}

class SimpleKeyboardPage extends StatefulWidget {
  const SimpleKeyboardPage({super.key});

  @override
  State<SimpleKeyboardPage> createState() => _SimpleKeyboardPageState();
}

class _SimpleKeyboardPageState extends State<SimpleKeyboardPage> {
  final TextEditingController _textController = TextEditingController();
  String _currentLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Simple Indica Keyboard',
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
            
            // This is the new simplified way to use the keyboard!
            Expanded(
              child: IndicaKeyboardField(
                supportedLanguages: const ['en', 'hi', 'mr'],
                textController: _textController,
                primaryColor: Colors.blue,
                onLanguageChanged: (language) {
                  setState(() {
                    _currentLanguage = language;
                  });
                },
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
                Text(
                  'Text Length: ${_textController.text.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
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