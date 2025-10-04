import 'package:flutter/foundation.dart';
import '../models/keyboard_layout.dart';

/// Enum for three-state shift key behavior
enum ShiftState {
  off,        // lowercase
  single,     // capitalize next letter only
  capsLock,   // all letters capitalized
}

/// Controller for managing multilingual keyboard state and operations
class KeyboardController extends ChangeNotifier {
  // Current language
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  // Supported languages
  final List<String> _supportedLanguages;
  List<String> get supportedLanguages => _supportedLanguages;

  // Layout page management for non-English keyboards
  int _currentLayoutPage = 0;
  int get currentLayoutPage => _currentLayoutPage;

  // Selected letter for dynamic top row (vowel attachments)
  String? _selectedLetter;
  String? get selectedLetter => _selectedLetter;

  // Three-state shift key management (only for English)
  ShiftState _shiftState = ShiftState.off;
  ShiftState get shiftState => _shiftState;
  bool get isUpperCase => _shiftState != ShiftState.off && _currentLanguage == 'en';

  // Numeric keyboard toggle
  bool _showNumericKeyboard = false;
  bool get showNumericKeyboard => _showNumericKeyboard;

  // Callbacks
  final Function(String)? onTextInput;
  final Function(String)? onLanguageChanged;

  // Constructor
  KeyboardController({
    required List<String> supportedLanguages,
    String initialLanguage = 'en',
    this.onTextInput,
    this.onLanguageChanged,
  }) : _supportedLanguages = supportedLanguages {
    if (supportedLanguages.contains(initialLanguage)) {
      _currentLanguage = initialLanguage;
    }
  }

  /// Get current keyboard layout
  List<List<String>> getCurrentLayout() {
    if (_showNumericKeyboard) {
      return KeyboardLayout.getNumericLayout();
    }
    return KeyboardLayout.getLayoutForLanguage(
      _currentLanguage,
      page: _currentLayoutPage,
      selectedLetter: _selectedLetter,
    );
  }

  /// Switch to next language
  void switchToNextLanguage() {
    final currentIndex = _supportedLanguages.indexOf(_currentLanguage);
    final nextIndex = (currentIndex + 1) % _supportedLanguages.length;
    switchToLanguage(_supportedLanguages[nextIndex]);
  }

  /// Switch to specific language
  void switchToLanguage(String language) {
    if (_supportedLanguages.contains(language)) {
      _currentLanguage = language;
      _currentLayoutPage = 0; // Reset to first page
      _selectedLetter = null; // Clear selection
      _shiftState = ShiftState.off; // Reset shift state
      onLanguageChanged?.call(language);
      notifyListeners();
    }
  }

  /// Switch to next layout page (for non-English keyboards)
  void switchLayoutPage() {
    if (_currentLanguage == 'en') return; // English doesn't have layout pages
    
    final maxPages = KeyboardLayout.getMaxLayoutPages(_currentLanguage);
    _currentLayoutPage = (_currentLayoutPage + 1) % maxPages;
    _selectedLetter = null; // Clear selection when switching pages
    notifyListeners();
  }

  /// Get layout page indicator text
  String getLayoutPageText() {
    if (_currentLanguage == 'en') return '';
    final maxPages = KeyboardLayout.getMaxLayoutPages(_currentLanguage);
    return '${_currentLayoutPage + 1}/$maxPages';
  }

  /// Handle letter selection for dynamic top row
  void handleLetterSelection(String key) {
    // Check if the pressed key is a consonant
    if (KeyboardLayout.isConsonant(key, _currentLanguage)) {
      _selectedLetter = key;
    } 
    // For other keys (vowels, symbols), clear selection
    else if (_isMainVowel(key)) {
      _selectedLetter = null;
    }
    notifyListeners();
  }

  /// Toggle shift state (English only)
  void toggleShift() {
    if (_currentLanguage != 'en') return;

    switch (_shiftState) {
      case ShiftState.off:
        _shiftState = ShiftState.single;
        break;
      case ShiftState.single:
        _shiftState = ShiftState.capsLock;
        break;
      case ShiftState.capsLock:
        _shiftState = ShiftState.off;
        break;
    }
    notifyListeners();
  }

  /// Handle double tap for caps lock
  void handleShiftDoubleTap() {
    if (_currentLanguage != 'en') return;
    
    if (_shiftState == ShiftState.single) {
      _shiftState = ShiftState.capsLock;
      notifyListeners();
    }
  }

  /// Reset shift state after single use
  void resetShiftIfSingle() {
    if (_shiftState == ShiftState.single) {
      _shiftState = ShiftState.off;
      notifyListeners();
    }
  }

  /// Toggle numeric keyboard
  void toggleNumericKeyboard() {
    _showNumericKeyboard = !_showNumericKeyboard;
    notifyListeners();
  }

  /// Show numeric keyboard
  void setNumericKeyboard(bool show) {
    _showNumericKeyboard = show;
    notifyListeners();
  }

  /// Process key press
  void processKeyPress(String key) {
    // Handle letter selection for dynamic top row (Hindi/Marathi only)
    if (_currentLanguage != 'en' && _currentLayoutPage == 0) {
      handleLetterSelection(key);
    }

    // Handle case conversion for English
    String finalKey = key;
    if (isUpperCase && key.length == 1 && key.toLowerCase() != key.toUpperCase()) {
      finalKey = key.toUpperCase();
      resetShiftIfSingle(); // Reset shift after single use
    }

    // Send key to text input
    onTextInput?.call(finalKey);
  }

  /// Check if the key is a vowel attachment for the selected letter
  bool isVowelAttachment(String key) {
    if (_selectedLetter == null) return false;
    final attachments = KeyboardLayout.getVowelAttachments(_selectedLetter!, _currentLanguage);
    return attachments.contains(key);
  }

  /// Check if the key is a main vowel
  bool _isMainVowel(String key) {
    final mainVowels = KeyboardLayout.getMainVowels(_currentLanguage);
    return mainVowels.contains(key);
  }

  /// Check if the key is a second row attachment for the selected letter
  bool isSecondRowAttachment(String key) {
    if (_selectedLetter == null) return false;
    final attachments = KeyboardLayout.getSecondRowAttachments(_selectedLetter!, _currentLanguage);
    return attachments.contains(key);
  }

  /// Check if the key is a last row attachment for the selected letter
  bool isLastRowAttachment(String key) {
    if (_selectedLetter == null) return false;
    final attachments = KeyboardLayout.getLastRowAttachments(_selectedLetter!, _currentLanguage);
    return attachments.contains(key);
  }

  /// Handle special key press (backspace, space, etc.)
  void handleSpecialKey(String action) {
    switch (action) {
      case 'backspace':
        onTextInput?.call('⌫');
        break;
      case 'space':
        onTextInput?.call(' ');
        resetShiftIfSingle(); // Reset shift after space
        break;
      case 'enter':
        onTextInput?.call('\n');
        resetShiftIfSingle(); // Reset shift after enter
        break;
      default:
        onTextInput?.call(action);
    }
  }

  /// Clear all state
  void clear() {
    _selectedLetter = null;
    _shiftState = ShiftState.off;
    _currentLayoutPage = 0;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}