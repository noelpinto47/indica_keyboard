import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/keyboard_layout.dart';
import '../constants/keyboard_constants.dart';

// Enum for three-state shift key behavior
enum ShiftState {
  off,        // lowercase
  single,     // capitalize next letter only
  capsLock,   // all letters capitalized
}

/// Main multilingual keyboard widget based on MinimalExamKeyboard
class MultilingualKeyboard extends StatefulWidget {
  final List<String> supportedLanguages; // e.g., ['en', 'hi', 'mr']
  final Function(String)? onTextInput; // Optional fallback for non-native platforms
  final bool useNativeKeyboard; // Enable/disable native integration
  final Function(bool)? onDialogStateChanged; // Notify parent about dialog state
  final String initialLanguage;
  final Function(String)? onLanguageChanged;
  final Function(String)? onKeyPressed;
  final double? height;
  final Color? backgroundColor;
  final Color? keyColor;
  final Color? textColor;
  final Color? primaryColor;
  final bool showLanguageSwitcher;
  final bool enableHapticFeedback;
  
  const MultilingualKeyboard({
    super.key,
    required this.supportedLanguages,
    this.onTextInput,
    this.useNativeKeyboard = true,
    this.onDialogStateChanged,
    this.initialLanguage = 'en',
    this.onLanguageChanged,
    this.onKeyPressed,
    this.height,
    this.backgroundColor,
    this.keyColor,
    this.textColor,
    this.primaryColor,
    this.showLanguageSwitcher = true,
    this.enableHapticFeedback = true,
  });

  @override
  State<MultilingualKeyboard> createState() => _MultilingualKeyboardState();
}

class _MultilingualKeyboardState extends State<MultilingualKeyboard> {
  String _currentLanguage = 'en';
  final Map<String, List<List<String>>> _layouts = {};
  
  // Layout page management for non-English keyboards
  int _currentLayoutPage = 0;
  final Map<String, int> _maxLayoutPages = {'hi': 4, 'mr': 4}; // Hindi and Marathi have 4 pages
  
  // Selected letter for dynamic top row (vowel attachments)
  String? _selectedLetter;
  
  // Three-state shift key management (only for English)
  ShiftState _shiftState = ShiftState.off;
  bool get _isUpperCase => _shiftState != ShiftState.off && _currentLanguage == 'en';
  
  bool _showNumericKeyboard = false;
  
  // Double tap detection for caps lock
  DateTime? _lastShiftTap;
  static const doubleTapThreshold = Duration(milliseconds: 300);
  
  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.initialLanguage;
    _loadKeyboardLayouts();
  }
  
  void _loadKeyboardLayouts() {
    // Pre-load all language layouts into memory
    // No dynamic loading during typing = consistent performance
    for (final lang in widget.supportedLanguages) {
      _layouts[lang] = KeyboardLayout.getLayoutForLanguage(lang, page: 0);
    }
  }

  // Get current layout based on language, page, and selected letter
  List<List<String>> _getCurrentLayout() {
    if (_showNumericKeyboard) {
      return KeyboardLayout.getNumericLayout();
    }
    return KeyboardLayout.getLayoutForLanguage(
      _currentLanguage, 
      page: _currentLayoutPage,
      selectedLetter: _selectedLetter,
    );
  }

  // Switch to next layout page (for non-English keyboards)
  void _switchLayoutPage() {
    if (_currentLanguage == 'en') return; // English doesn't have layout pages
    
    final maxPages = _maxLayoutPages[_currentLanguage] ?? 1;
    setState(() {
      _currentLayoutPage = (_currentLayoutPage + 1) % maxPages;
      _selectedLetter = null; // Clear selection when switching pages
    });
  }

  // Get layout page indicator text
  String _getLayoutPageText() {
    if (_currentLanguage == 'en') return '';
    final maxPages = _maxLayoutPages[_currentLanguage] ?? 1;
    return '${_currentLayoutPage + 1}/$maxPages';
  }

  // CRITICAL PATH: This runs on every key press
  Future<void> _onKeyPress(String key) async {
    try {
      // Handle three-state capitalization
      String finalKey = key;
      if (_isUpperCase && key.length == 1 && key.toLowerCase() != key.toUpperCase()) {
        finalKey = key.toUpperCase();
        
        // Auto-reset shift state after single character for 'single' mode
        if (_shiftState == ShiftState.single) {
          setState(() {
            _shiftState = ShiftState.off;
          });
        }
      }
      
      // Send text to callback
      widget.onTextInput?.call(finalKey);
      widget.onKeyPressed?.call(finalKey);
      
    } catch (e) {
      // Fallback handling
      widget.onTextInput?.call(key);
    }
  }

  void _onBackspace() {
    widget.onTextInput?.call('⌫');
  }

  void _toggleCase() {
    if (_currentLanguage == 'en') {
      // Handle shift key for English
      final now = DateTime.now();
      if (_lastShiftTap != null && now.difference(_lastShiftTap!) < doubleTapThreshold) {
        // Double tap: activate caps lock
        setState(() {
          _shiftState = ShiftState.capsLock;
        });
      } else {
        // Single tap: cycle through states
        setState(() {
          switch (_shiftState) {
            case ShiftState.off:
              _shiftState = ShiftState.single;
              break;
            case ShiftState.single:
            case ShiftState.capsLock:
              _shiftState = ShiftState.off;
              break;
          }
        });
      }
      _lastShiftTap = now;
    } else {
      // Handle layout page switching for non-English keyboards
      _switchLayoutPage();
    }
  }

  void _toggleNumericKeyboard() {
    setState(() {
      _showNumericKeyboard = !_showNumericKeyboard;
    });
  }

  void _toggleLanguageSelector() {
    if (widget.supportedLanguages.length > 1) {
      _showLanguageModal();
    }
  }

  void _switchLanguage(String language) {
    if (mounted) {
      setState(() {
        _currentLanguage = language;
        _currentLayoutPage = 0; // Reset to first page when switching languages
        _selectedLetter = null; // Clear selection when switching languages
      });
      widget.onLanguageChanged?.call(language);
    }
  }

  /// Get display code for language indicator on spacebar
  String _getLanguageDisplayCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'eng';
      case 'hi':
        return 'hin';
      case 'mr':
        return 'mar';
      default:
        return languageCode.toLowerCase();
    }
  }

  /// Helper method to get shift key icon path based on state
  String _getShiftIconPath(ShiftState shiftState) {
    switch (shiftState) {
      case ShiftState.capsLock:
        return 'packages/indica_keyboard/assets/icons/caps-lock-hold.svg'; // Caps lock enabled
      case ShiftState.single:
        return 'packages/indica_keyboard/assets/icons/caps-lock-enabled.svg'; // Single tap - hold state
      case ShiftState.off:
        return 'packages/indica_keyboard/assets/icons/default-caps-lock-off.svg'; // Default off state
    }
  }

  /// Helper method to get the effective primary color
  Color _getEffectivePrimaryColor() {
    return widget.primaryColor ?? KeyboardConstants.primary;
  }

  /// Helper method to get the effective primary light color
  Color _getEffectivePrimaryLightColor() {
    return widget.primaryColor?.withValues(alpha: 0.1) ?? KeyboardConstants.primaryLight;
  }

  void _showLanguageModal() async {
    // Notify parent that dialog is opening
    widget.onDialogStateChanged?.call(true);
    
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: KeyboardConstants.modalBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal title
                  const Text(
                    'Select Language',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: KeyboardConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Language options
                  ...widget.supportedLanguages.map((lang) {
                    final isSelected = _currentLanguage == lang;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: KeyboardConstants.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _switchLanguage(lang);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? _getEffectivePrimaryLightColor() 
                                  : KeyboardConstants.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? _getEffectivePrimaryColor() 
                                    : KeyboardConstants.borderLight,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    KeyboardLayout.getLanguageName(lang),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                      color: isSelected 
                                          ? _getEffectivePrimaryColor() 
                                          : KeyboardConstants.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: _getEffectivePrimaryColor(),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    // Notify parent that dialog is closed
    widget.onDialogStateChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    // Responsive keyboard height management
    final maxKeyboardHeight = isLandscape 
        ? screenSize.height * 0.4  // 40% max in landscape
        : screenSize.height * 0.5; // 50% max in portrait
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: widget.height ?? maxKeyboardHeight,
        minHeight: 0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? KeyboardConstants.keyboardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: _buildAdaptiveKeyboardLayout(widget.height ?? maxKeyboardHeight),
      ),
    );
  }

  Widget _buildAdaptiveKeyboardLayout(double availableHeight) {
    return _showNumericKeyboard 
        ? _buildAdaptiveNumericKeyboardLayout(availableHeight)
        : _buildAdaptiveAlphaKeyboardLayout(availableHeight);
  }

  Widget _buildAdaptiveAlphaKeyboardLayout(double availableHeight) {
    final layout = _getCurrentLayout();
    
    // Calculate adaptive key height dynamically
    const double padding = 8.0; // Total padding from container
    final int layoutRows = layout.length; // Dynamic based on layout array length
    final int totalRows = layoutRows + 1; // Layout rows + 1 unified bottom row
    
    // Set natural key heights based on screen orientation
    const double preferredKeyHeight = 45.0; // Comfortable key size
    const double minKeyHeight = 30.0; // Minimum usability
    const double maxKeyHeight = 50.0; // Maximum comfort
    
    // Calculate if we need to compress keys to fit in available space
    final double naturalKeyboardHeight = (preferredKeyHeight * totalRows) + padding;
    final double adaptiveKeyHeight = naturalKeyboardHeight <= availableHeight
        ? preferredKeyHeight // Use natural size if it fits
        : ((availableHeight - padding) / totalRows).clamp(minKeyHeight, maxKeyHeight); // Compress if needed
    
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Build all layout rows dynamically
          ...layout.asMap().entries.map((entry) {
            final int index = entry.key;
            final List<String> row = entry.value;
            final bool isLastRow = index == layout.length - 1;
            
            return Flexible(
              child: isLastRow
                  // Last row uses buildBottomRow for shift and backspace functionality
                  ? _buildBottomRow(
                      row, 
                      adaptiveKeyHeight,
                    )
                  // All other rows use regular buildKeyRow
                  : _buildKeyRow(
                      row, 
                      adaptiveKeyHeight,
                    ),
            );
          }),
          
          // Unified bottom row (spacebar, etc.)
          Flexible(
            child: _buildAdaptiveUnifiedBottomRow(adaptiveKeyHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveNumericKeyboardLayout(double availableHeight) {
    final layout = KeyboardLayout.getNumericLayout();
    
    // Calculate adaptive key height for numeric layout dynamically
    const double padding = 8.0; // Total padding from container
    final int layoutRows = layout.length; // Dynamic based on layout array length
    final int totalRows = layoutRows + 1; // Layout rows + 1 unified bottom row
    
    // Set natural key heights based on screen orientation
    const double preferredKeyHeight = 45.0; // Comfortable key size
    const double minKeyHeight = 30.0; // Minimum usability
    const double maxKeyHeight = 50.0; // Maximum comfort
    
    // Calculate if we need to compress keys to fit in available space
    final double naturalKeyboardHeight = (preferredKeyHeight * totalRows) + padding;
    final double adaptiveKeyHeight = naturalKeyboardHeight <= availableHeight
        ? preferredKeyHeight // Use natural size if it fits
        : ((availableHeight - padding) / totalRows).clamp(minKeyHeight, maxKeyHeight); // Compress if needed
    
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Build all layout rows dynamically
          ...layout.asMap().entries.map((entry) {
            final int index = entry.key;
            final List<String> row = entry.value;
            final bool isLastRow = index == layout.length - 1;
            
            return Flexible(
              child: isLastRow
                  // Last row uses buildNumericBottomRow for special handling
                  ? _buildNumericBottomRow(
                      row, 
                      adaptiveKeyHeight,
                    )
                  // All other rows use regular buildKeyRow
                  : _buildKeyRow(
                      row, 
                      adaptiveKeyHeight,
                    ),
            );
          }),

          // Unified bottom row (spacebar, etc.)
          Flexible(
            child: _buildAdaptiveUnifiedBottomRow(adaptiveKeyHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys, double keyHeight) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: _buildKey(key, keyHeight),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow(List<String> keys, double keyHeight) {
    return Row(
      children: [
        // Shift key for English, Layout switcher for other languages
        Expanded(
          child: (_currentLanguage == 'en') 
            ? _buildShiftKey(keyHeight)
            : _buildLayoutSwitcherKey(keyHeight),
        ),
        
        // Letter keys
        ...keys.map((key) {
          return Expanded(
            child: _buildKey(key, keyHeight),
          );
        }),
        
        // Backspace key
        Expanded(
          flex: 1,
          child: _buildSpecialKey(
            '⌫',
            onTap: _onBackspace,
            keyHeight: keyHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildNumericBottomRow(List<String> keys, double keyHeight) {
    return Row(
      children: [
        // Special symbols key (wider)
        Expanded(
          flex: 1,
          child: _buildSpecialKey(
            keys[0], // 'more'
            onTap: () {
              if (keys[0].contains('more')) {
                return;
              } else {
                _onKeyPress(keys[0]);
              }
            },
            keyHeight: keyHeight,
          ),
        ),
        
        // Regular symbol keys
        ...keys.skip(1).map((key) {
          return Expanded(
            child: _buildKey(key, keyHeight),
          );
        }),
        
        // Backspace key
        Expanded(
          flex: 1,
          child: _buildSpecialKey(
            '⌫',
            onTap: _onBackspace,
            keyHeight: keyHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveUnifiedBottomRow(double keyHeight) {
    return Row(
      children: [
        // Toggle button (?123 or ABC)
        Expanded(
          flex: 2,
          child: _buildSpecialKey(
            _showNumericKeyboard ? 'ABC' : '?123',
            onTap: _toggleNumericKeyboard,
            keyHeight: keyHeight,
          ),
        ),
        
        // Comma key
        Expanded(
          flex: 2,
          child: _buildKey(',', keyHeight),
        ),
        
        // Spacebar with language switching and language indicator
        Expanded(
          flex: 6,
          child: Material(
            color: widget.keyColor ?? KeyboardConstants.keyBackground,
            borderRadius: BorderRadius.circular(6),
            elevation: 1,
            child: InkWell(
              onTap: () => _onKeyPress(' '),
              onLongPress: widget.showLanguageSwitcher ? _toggleLanguageSelector : null,
              borderRadius: BorderRadius.circular(6),
              splashColor: KeyboardConstants.keySplashWithAlpha,
              highlightColor: KeyboardConstants.keyHighlightWithAlpha,
              child: Container(
                height: keyHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: KeyboardConstants.keyBorder, width: 1),
                ),
                child: Stack(
                  children: [
                    // Centered space symbol
                    const Center(
                      child: Text(
                        '␣',
                        style: TextStyle(
                          fontSize: 18,
                          color: KeyboardConstants.keyText,
                        ),
                      ),
                    ),
                    // Language indicator positioned on the right
                    if (widget.showLanguageSwitcher)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            _getLanguageDisplayCode(_currentLanguage),
                            style: const TextStyle(
                              fontSize: 11,
                              color: KeyboardConstants.textGrey,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Period key
        Expanded(
          flex: 2,
          child: _buildKey('.', keyHeight),
        ),
        
        // Enter key
        Expanded(
          flex: 2,
          child: _buildSpecialKey(
            '↵',
            onTap: () => _onKeyPress('\n'),
            keyHeight: keyHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String key, double keyHeight) {
    String displayKey = key;
    
    // Handle case conversion for letters
    if (_isUpperCase && key.length == 1 && key.toLowerCase() != key.toUpperCase()) {
      displayKey = key.toUpperCase();
    }
    
    return Container(
      height: keyHeight,
      margin: const EdgeInsets.all(2.0),
      child: Material(
        color: widget.keyColor ?? KeyboardConstants.keyBackground,
        borderRadius: BorderRadius.circular(6),
        elevation: 1,
        child: InkWell(
          onTap: () => _onKeyPress(displayKey),
          borderRadius: BorderRadius.circular(6),
          splashColor: KeyboardConstants.keySplashWithAlpha,
          highlightColor: KeyboardConstants.keyHighlightWithAlpha,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: KeyboardConstants.keyBorder, width: 1),
            ),
            child: Center(
              child: Text(
                displayKey,
                style: TextStyle(
                  fontSize: (keyHeight * 0.4).clamp(12.0, 18.0),
                  fontWeight: FontWeight.normal,
                  color: widget.textColor ?? KeyboardConstants.keyText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(String label, {VoidCallback? onTap, double? keyHeight}) {
    return Container(
      height: keyHeight,
      margin: const EdgeInsets.all(2.0),
      child: Material(
        color: KeyboardConstants.specialKeyDefault,
        borderRadius: BorderRadius.circular(6),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          splashColor: KeyboardConstants.specialKeySplashWithAlpha,
          highlightColor: KeyboardConstants.specialKeyHighlightWithAlpha,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: KeyboardConstants.specialKeyBorder, 
                width: 1
              ),
            ),
            child: Center(
              child: FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: (keyHeight != null ? (keyHeight * 0.35).toDouble() : 16.0).clamp(10.0, 16.0),
                    color: KeyboardConstants.textOnLight,
                    fontWeight: FontWeight.w500,
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

  Widget _buildShiftKey(double keyHeight) {
    final iconPath = _getShiftIconPath(_shiftState);
    
    return Container(
      height: keyHeight,
      margin: const EdgeInsets.all(2.0),
      child: Material(
        color: KeyboardConstants.specialKeyDefault,
        borderRadius: BorderRadius.circular(6),
        elevation: 1,
        child: InkWell(
          onTap: _toggleCase,
          borderRadius: BorderRadius.circular(6),
          splashColor: KeyboardConstants.specialKeySplashWithAlpha,
          highlightColor: KeyboardConstants.specialKeyHighlightWithAlpha,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: KeyboardConstants.specialKeyBorder, 
                width: 1
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: _shiftState == ShiftState.capsLock ? 12 : 8,
                height: _shiftState == ShiftState.capsLock ? 12 : 8,
                colorFilter: _shiftState == ShiftState.off 
                    ? ColorFilter.mode(Colors.black26, BlendMode.srcIn)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutSwitcherKey(double keyHeight) {
    return Container(
      height: keyHeight,
      margin: const EdgeInsets.all(2.0),
      child: Material(
        color: KeyboardConstants.specialKeyDefault,
        borderRadius: BorderRadius.circular(6),
        elevation: 1,
        child: InkWell(
          onTap: _toggleCase,
          borderRadius: BorderRadius.circular(6),
          splashColor: KeyboardConstants.specialKeySplashWithAlpha,
          highlightColor: KeyboardConstants.specialKeyHighlightWithAlpha,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: KeyboardConstants.specialKeyBorder, 
                width: 1
              ),
            ),
            child: Center(
              child: Text(
                _getLayoutPageText(),
                style: TextStyle(
                  fontSize: (keyHeight * 0.35).clamp(10.0, 16.0),
                  color: KeyboardConstants.textOnLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}