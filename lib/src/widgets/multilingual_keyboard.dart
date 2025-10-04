import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/keyboard_layout.dart';
import '../services/keyboard_controller.dart';
import '../constants/keyboard_constants.dart';

/// Main multilingual keyboard widget that can be used as a plugin
class MultilingualKeyboard extends StatefulWidget {
  /// List of supported languages (e.g., ['en', 'hi', 'mr'])
  final List<String> supportedLanguages;
  
  /// Initial language to display
  final String initialLanguage;
  
  /// Callback when text is input
  final Function(String)? onTextInput;
  
  /// Callback when language is changed
  final Function(String)? onLanguageChanged;
  
  /// Callback when a key is pressed (for additional handling)
  final Function(String)? onKeyPressed;
  
  /// Custom height for the keyboard
  final double? height;
  
  /// Custom theme colors
  final Color? backgroundColor;
  final Color? keyColor;
  final Color? textColor;
  
  /// Whether to show language switcher
  final bool showLanguageSwitcher;
  
  /// Whether to enable haptic feedback
  final bool enableHapticFeedback;

  const MultilingualKeyboard({
    super.key,
    required this.supportedLanguages,
    this.initialLanguage = 'en',
    this.onTextInput,
    this.onLanguageChanged,
    this.onKeyPressed,
    this.height,
    this.backgroundColor,
    this.keyColor,
    this.textColor,
    this.showLanguageSwitcher = true,
    this.enableHapticFeedback = true,
  });

  @override
  State<MultilingualKeyboard> createState() => _MultilingualKeyboardState();
}

class _MultilingualKeyboardState extends State<MultilingualKeyboard> {
  late KeyboardController _controller;
  late DateTime? _lastShiftTap;
  static const Duration _doubleTapThreshold = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _controller = KeyboardController(
      supportedLanguages: widget.supportedLanguages,
      initialLanguage: widget.initialLanguage,
      onTextInput: _handleTextInput,
      onLanguageChanged: widget.onLanguageChanged,
    );
    _lastShiftTap = null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Handle text input with additional processing
  void _handleTextInput(String text) {
    // Handle vowel, second row, and last row attachment replacement for Hindi/Marathi
    if (_shouldReplaceConsonantWithAttachment(text)) {
      _replaceConsonantWithAttachment(text);
      return;
    }

    // Provide haptic feedback if enabled
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Call the provided callback
    widget.onTextInput?.call(text);
    widget.onKeyPressed?.call(text);
  }

  /// Check if we should replace consonant with attachment
  bool _shouldReplaceConsonantWithAttachment(String key) {
    return _controller.currentLanguage != 'en' && 
           _controller.currentLayoutPage == 0 && 
           _controller.selectedLetter != null &&
           (_controller.isVowelAttachment(key) || 
            _controller.isSecondRowAttachment(key) || 
            _controller.isLastRowAttachment(key));
  }

  /// Replace the last consonant with consonant+vowel attachment
  void _replaceConsonantWithAttachment(String attachment) {
    // Send backspace then the attachment
    widget.onTextInput?.call('⌫');
    widget.onTextInput?.call(attachment);
    _controller.handleLetterSelection(''); // Clear selection
  }

  /// Handle shift key press with double-tap detection
  void _handleShiftPress() {
    final now = DateTime.now();
    if (_lastShiftTap != null && 
        now.difference(_lastShiftTap!) < _doubleTapThreshold) {
      // Double tap detected
      _controller.handleShiftDoubleTap();
    } else {
      // Single tap
      _controller.toggleShift();
    }
    _lastShiftTap = now;
  }

  /// Build a regular key
  Widget _buildKey(String key, {double? keyHeight}) {
    String displayKey = key;
    
    // Handle case conversion for letters
    if (_controller.isUpperCase && key.length == 1 && key.toLowerCase() != key.toUpperCase()) {
      displayKey = key.toUpperCase();
    }
    
    return Expanded(
      child: Container(
        height: keyHeight ?? KeyboardConstants.defaultKeyHeight,
        margin: const EdgeInsets.all(KeyboardConstants.keySpacing / 2),
        child: Material(
          color: widget.keyColor ?? KeyboardConstants.keyBackground,
          borderRadius: BorderRadius.circular(KeyboardConstants.keyBorderRadius),
          elevation: KeyboardConstants.keyElevation,
          child: InkWell(
            onTap: () => _controller.processKeyPress(displayKey),
            borderRadius: BorderRadius.circular(KeyboardConstants.keyBorderRadius),
            splashColor: KeyboardConstants.keySplashWithAlpha,
            highlightColor: KeyboardConstants.keyHighlightWithAlpha,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KeyboardConstants.keyBorderRadius),
                border: Border.all(color: KeyboardConstants.keyBorder, width: 1),
              ),
              child: Center(
                child: Text(
                  displayKey,
                  style: TextStyle(
                    fontSize: KeyboardConstants.defaultFontSize,
                    fontWeight: FontWeight.normal,
                    color: widget.textColor ?? KeyboardConstants.keyText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a special key (shift, space, backspace, etc.)
  Widget _buildSpecialKey({
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    double flex = 1.0,
    double? keyHeight,
    Widget? icon,
  }) {
    final keyColor = isActive 
        ? KeyboardConstants.primary 
        : KeyboardConstants.specialKeyDefault;
    
    final textColor = isActive 
        ? KeyboardConstants.textOnPrimary 
        : KeyboardConstants.textOnLight;

    return Expanded(
      flex: flex.round(),
      child: Container(
        height: keyHeight ?? KeyboardConstants.defaultKeyHeight,
        margin: const EdgeInsets.all(KeyboardConstants.keySpacing / 2),
        child: Material(
          color: keyColor,
          borderRadius: BorderRadius.circular(KeyboardConstants.keyBorderRadius),
          elevation: KeyboardConstants.keyElevation,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(KeyboardConstants.keyBorderRadius),
            splashColor: KeyboardConstants.specialKeySplashWithAlpha,
            highlightColor: KeyboardConstants.specialKeyHighlightWithAlpha,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KeyboardConstants.keyBorderRadius),
                border: Border.all(
                  color: KeyboardConstants.specialKeyBorder, 
                  width: 1
                ),
              ),
              child: Center(
                child: icon ?? Text(
                  label,
                  style: TextStyle(
                    fontSize: KeyboardConstants.defaultFontSize,
                    fontWeight: FontWeight.normal,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build keyboard row
  Widget _buildKeyboardRow(List<String> keys, {double? keyHeight}) {
    return Row(
      children: keys.map((key) => _buildKey(key, keyHeight: keyHeight)).toList(),
    );
  }

  /// Build special control row
  Widget _buildControlRow() {
    const keyHeight = KeyboardConstants.defaultKeyHeight;
    
    return Row(
      children: [
        // Shift key (English only)
        if (_controller.currentLanguage == 'en')
          _buildSpecialKey(
            label: '⇧',
            onTap: _handleShiftPress,
            isActive: _controller.shiftState != ShiftState.off,
            flex: 1.5,
            keyHeight: keyHeight,
          ),
        
        // Language switcher
        if (widget.showLanguageSwitcher && widget.supportedLanguages.length > 1)
          _buildSpecialKey(
            label: KeyboardLayout.getLanguageName(_controller.currentLanguage),
            onTap: _controller.switchToNextLanguage,
            flex: 2.0,
            keyHeight: keyHeight,
          ),
        
        // Layout page switcher (Hindi/Marathi only)
        if (_controller.currentLanguage != 'en')
          _buildSpecialKey(
            label: _controller.getLayoutPageText(),
            onTap: _controller.switchLayoutPage,
            flex: 1.0,
            keyHeight: keyHeight,
          ),
        
        // Space bar
        _buildSpecialKey(
          label: 'Space',
          onTap: () => _controller.handleSpecialKey('space'),
          flex: 4.0,
          keyHeight: keyHeight,
        ),
        
        // Number toggle
        _buildSpecialKey(
          label: _controller.showNumericKeyboard ? 'ABC' : '123',
          onTap: _controller.toggleNumericKeyboard,
          flex: 1.5,
          keyHeight: keyHeight,
        ),
        
        // Backspace
        _buildSpecialKey(
          label: '⌫',
          onTap: () => _controller.handleSpecialKey('backspace'),
          flex: 1.5,
          keyHeight: keyHeight,
          icon: const Icon(Icons.backspace_outlined, color: KeyboardConstants.textOnLight),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final layout = _controller.getCurrentLayout();
        final keyboardHeight = widget.height ?? (layout.length + 1) * (KeyboardConstants.defaultKeyHeight + KeyboardConstants.keySpacing);
        
        return Container(
          height: keyboardHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? KeyboardConstants.keyboardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(KeyboardConstants.keySpacing),
            child: Column(
              children: [
                // Keyboard layout rows
                ...layout.map((row) => Expanded(
                  child: _buildKeyboardRow(row),
                )),
                
                // Control row
                SizedBox(
                  height: KeyboardConstants.defaultKeyHeight + KeyboardConstants.keySpacing,
                  child: _buildControlRow(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}