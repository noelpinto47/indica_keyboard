import 'dart:async';
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
  bool _isDialogOpen = false; // Track dialog state
  String _currentLanguage = 'en';
  
  // Native integration state
  bool _isInitializing = true;
  Timer? _statsUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeNativeSupport();
    
    // Update stats display every 2 seconds to show real-time usage
    _statsUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) setState(() {}); // Trigger rebuild to refresh stats
    });
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

  /// Initialize native support (automatic fallback to Dart if not available)
  Future<void> _initializeNativeSupport() async {
    try {
      await IndicaNativeService.initialize();
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      // Silent fallback - user doesn't need to know
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _statsUpdateTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Indica Keyboard Demo',
          style: TextStyle(color: Colors.white),
        ),
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
                  const SizedBox(height: 8),
                  _buildNativeStatusWidget(),
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
                      showCursor: true,
                      readOnly: false,
                      enableInteractiveSelection: true,
                      keyboardType: TextInputType.none,
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
                        child: Text(
                          _showKeyboard ? 'Hide Keyboard' : 'Show Keyboard',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Indica keyboard
          if (_showKeyboard)
            IndicaKeyboard(
              supportedLanguages: const ['en', 'hi', 'mr'],
              initialLanguage: 'en',
              textController: _textController,
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

  /// Build processing mode indicator with detailed statistics
  Widget _buildNativeStatusWidget() {
    if (_isInitializing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Initializing...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    final isNative = IndicaNativeService.isUsingNativeProcessing;
    final stats = IndicaNativeService.getProcessingStats();
    
    final statusColor = isNative ? Colors.green : Colors.blue;
    final statusText = isNative ? 'Native Processing' : 'Dart Processing';
    final icon = isNative ? Icons.flash_on : Icons.code;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main status indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Processing statistics
            if (stats['totalCalls'] > 0) ...[
              Text(
                'Processing Stats:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('🚀 Native: ${stats['nativeCallCount']}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 12),
                  Text('🔄 Dart: ${stats['dartFallbackCount']}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 12),
                  Text('📊 ${stats['nativePercentage']}% native', 
                       style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.green[700])),
                ],
              ),
            ] else
              Text(
                'No processing calls yet - start typing!',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
