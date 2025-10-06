import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/keyboard_layout.dart';
import '../constants/keyboard_constants.dart';
import '../services/indica_native_service.dart';

// Enum for three-state shift key behavior
enum ShiftState {
  off,        // lowercase
  single,     // capitalize next letter only
  capsLock,   // all letters capitalized
}

/// A complete keyboard input solution that provides both a text field and keyboard
class IndicaKeyboardField extends StatefulWidget {
  final List<String> supportedLanguages;
  final TextEditingController? textController;
  final String? hintText;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final Function(String)? onLanguageChanged;
  final Color? primaryColor;
  final bool showLanguageSwitcher;
  final bool enableHapticFeedback;
  final double? keyboardHeight;

  const IndicaKeyboardField({
    super.key,
    required this.supportedLanguages,
    this.textController,
    this.hintText = 'Tap here to start typing...',
    this.textStyle,
    this.decoration,
    this.onLanguageChanged,
    this.primaryColor,
    this.showLanguageSwitcher = true,
    this.enableHapticFeedback = true,
    this.keyboardHeight,
  });

  @override
  State<IndicaKeyboardField> createState() => _IndicaKeyboardFieldState();
}

class _IndicaKeyboardFieldState extends State<IndicaKeyboardField> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _showKeyboard = false;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _textController = widget.textController ?? TextEditingController();
    _focusNode = FocusNode();
    
    // Initialize native service for automatic high-performance processing
    IndicaNativeService.initialize();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showKeyboard = true;
        });
      } else {
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
    if (widget.textController == null) {
      _textController.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _handleLanguageChanged(String language) {
    widget.onLanguageChanged?.call(language);
  }

  void _handleDialogStateChanged(bool isOpen) {
    setState(() {
      _isDialogOpen = isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          style: widget.textStyle ?? const TextStyle(fontSize: 18),
          decoration: widget.decoration ?? InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(16),
          ),
          keyboardType: TextInputType.none,
          showCursor: true,
          readOnly: false,
          enableInteractiveSelection: true,
        ),
        if (_showKeyboard)
          IndicaKeyboard(
            supportedLanguages: widget.supportedLanguages,
            textController: _textController,
            onLanguageChanged: _handleLanguageChanged,
            onDialogStateChanged: _handleDialogStateChanged,
            showLanguageSwitcher: widget.showLanguageSwitcher,
            enableHapticFeedback: widget.enableHapticFeedback,
            primaryColor: widget.primaryColor,
            height: widget.keyboardHeight,
          ),
      ],
    );
  }
}

/// Main Indica keyboard widget based on MinimalExamKeyboard
class IndicaKeyboard extends StatefulWidget {
  final List<String> supportedLanguages; // e.g., ['en', 'hi', 'mr']
  final TextEditingController? textController; // Text controller for input handling
  final FocusNode? focusNode; // Focus node for keyboard visibility management
  final Function(bool)? onKeyboardVisibilityChanged; // Callback for keyboard visibility changes
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
  final bool autoManageKeyboardVisibility; // Auto show/hide keyboard based on focus
  
  const IndicaKeyboard({
    super.key,
    required this.supportedLanguages,
    this.textController,
    this.focusNode,
    this.onKeyboardVisibilityChanged,
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
    this.autoManageKeyboardVisibility = true,
  });

  @override
  State<IndicaKeyboard> createState() => _IndicaKeyboardState();
}

class _IndicaKeyboardState extends State<IndicaKeyboard> {
  String _currentLanguage = 'en';
  final Map<String, List<List<String>>> _layouts = {};
  
  // Focus and keyboard visibility management
  late FocusNode _internalFocusNode;
  bool _keyboardVisible = false;
  final bool _isDialogOpen = false;
  
  // Conjunct consonant formation state
  bool _conjunctMode = false; // Whether conjunct formation is active
  String? _pendingConsonant; // The consonant waiting to be joined
  
  // Auto-capitalization state (English only)
  final bool _shouldAutoCapitalize = true; // Start with capital for first letter
  bool _justUsedAutoCapitalization = false; // Track if we just auto-capitalized
  
  // Performance optimizations: Cache frequently accessed values
  late final Map<String, TextStyle> _cachedTextStyles = {};
  late final Map<String, BoxDecoration> _cachedDecorations = {};
  List<List<String>>? _cachedCurrentLayout;
  bool _layoutCacheInvalid = true;
  
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
  
  // Performance: Pre-computed constants
  static const _keyBorderRadius = BorderRadius.all(Radius.circular(6));
  
  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.initialLanguage;
    
    // Initialize native service for automatic high-performance processing
    IndicaNativeService.initialize();
    
    // Initialize focus node (use provided one or create internal)
    _internalFocusNode = widget.focusNode ?? FocusNode();
    
    // Set up focus listener for automatic keyboard visibility management
    if (widget.autoManageKeyboardVisibility) {
      _internalFocusNode.addListener(_handleFocusChange);
    }
    
    // Listen to text changes to update keyboard capitalization display
    if (widget.textController != null) {
      widget.textController!.addListener(() {
        if (mounted && _currentLanguage == 'en' && _shouldAutoCapitalize) {
          setState(() {}); // Rebuild keyboard to show/hide capitalization
        }
      });
    }
    
    _loadKeyboardLayouts();
    
    // Performance: Pre-warm all caches for zero-latency access
    KeyboardLayout.preWarmAllCaches();
  }
  
  void _loadKeyboardLayouts() {
    // Pre-load ALL language layouts into memory for all pages
    // No dynamic loading during typing = consistent performance
    for (final lang in widget.supportedLanguages) {
      _layouts[lang] = KeyboardLayout.getLayoutForLanguage(lang, page: 0);
      
      // Pre-load all pages for non-English languages
      if (lang != 'en') {
        final maxPages = _maxLayoutPages[lang] ?? 1;
        for (int page = 0; page < maxPages; page++) {
          KeyboardLayout.getLayoutForLanguage(lang, page: page);
        }
      }
    }
    
    // Pre-load numeric layout
    KeyboardLayout.getNumericLayout();
    
    // Pre-compute text styles for different key heights
    _precomputeStyles();
  }
  
  void _precomputeStyles() {
    // Pre-compute common text styles to avoid repeated calculations
    for (double height in [30.0, 35.0, 40.0, 45.0, 50.0]) {
      final fontSize = (height * 0.4).clamp(12.0, 18.0);
      _cachedTextStyles[height.toString()] = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.normal,
        color: widget.textColor ?? KeyboardConstants.keyText,
      );
    }
    
    // Pre-compute decorations
    _cachedDecorations['key'] = BoxDecoration(
      borderRadius: _keyBorderRadius,
      border: Border.all(color: KeyboardConstants.keyBorder, width: 1),
    );
    
    _cachedDecorations['special'] = BoxDecoration(
      borderRadius: _keyBorderRadius,
      border: Border.all(color: KeyboardConstants.specialKeyBorder, width: 1),
    );
  }

  // Internal text input handling
  void _handleTextInput(String text) {
    final controller = widget.textController;
    if (controller == null) {
      // Fallback to callback if no controller provided
      widget.onTextInput?.call(text);
      return;
    }

    if (text == '⌫') {
      // Handle backspace at cursor position
      final currentText = controller.text;
      final selection = controller.selection;
      
      if (currentText.isNotEmpty && selection.start > 0) {
        // Delete character before cursor
        final newText = currentText.replaceRange(
          selection.start - 1,
          selection.start,
          '',
        );
        final newOffset = selection.start - 1;
        
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
        );
      }
    } else {
      // Handle regular text input at cursor position
      final currentText = controller.text;
      final selection = controller.selection;
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      final newOffset = selection.start + text.length;

      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
  }

  // Focus handling for automatic keyboard visibility
  void _handleFocusChange() {
    if (_internalFocusNode.hasFocus) {
      _setKeyboardVisible(true);
    } else {
      // Don't hide keyboard immediately on focus lost
      // This prevents keyboard from disappearing when dialogs open
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_isDialogOpen && !_internalFocusNode.hasFocus) {
          _setKeyboardVisible(false);
        }
      });
    }
  }

  void _setKeyboardVisible(bool visible) {
    if (_keyboardVisible != visible) {
      setState(() {
        _keyboardVisible = visible;
      });
      widget.onKeyboardVisibilityChanged?.call(visible);
    }
  }



  @override
  void dispose() {
    // Only dispose if we created the focus node internally
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  // Helper method to check if a character is a Devanagari consonant
  bool _isDevanagariConsonant(String char) {
    if (char.isEmpty || _currentLanguage == 'en') return false;
    
    // Devanagari consonant range (क to ह) 
    final int charCode = char.runes.first;
    return charCode >= 0x0915 && charCode <= 0x0939; // क(0x0915) to ह(0x0939)
  }



  // Helper method to detect sentence boundaries
  bool _isSentenceEnd(String text) {
    if (text.isEmpty) return true; // Start of text
    
    // Look for sentence-ending punctuation followed by space or at end
    final trimmed = text.trimRight();
    if (trimmed.isEmpty) return true;
    
    final lastChar = trimmed[trimmed.length - 1];
    return lastChar == '.' || lastChar == '!' || lastChar == '?';
  }

  // Helper method to determine if next character should be capitalized
  bool _shouldCapitalize() {
    if (_currentLanguage != 'en' || !_shouldAutoCapitalize) return false;
    
    // If we just used auto-capitalization, don't capitalize again until next sentence
    if (_justUsedAutoCapitalization) return false;
    
    final controller = widget.textController;
    if (controller == null) return false; // No controller, no capitalization
    
    final currentText = controller.text;
    if (currentText.isEmpty) return true; // Start of text
    
    // Check if we're at the beginning of a sentence
    return _isSentenceEnd(currentText);
  }

  // Handle conjunct formation logic - toggle on/off
  void _handleConjunctFormation() {
    if (_currentLanguage == 'en') return; // No conjunct for English
    
    // If already in conjunct mode, toggle it off
    if (_conjunctMode) {
      setState(() {
        _conjunctMode = false;
        _pendingConsonant = null;
      });
      return;
    }
    
    // Try to turn conjunct mode on
    final controller = widget.textController;
    if (controller == null) return;
    
    final text = controller.text;
    final selection = controller.selection;
    
    if (text.isEmpty || selection.start == 0) return;
    
    // Get the character just before the cursor
    final beforeCursor = text.substring(selection.start - 1, selection.start);
    
    if (_isDevanagariConsonant(beforeCursor)) {
      setState(() {
        _conjunctMode = true;
        _pendingConsonant = beforeCursor;
      });
      
      // Visual feedback - the button will highlight automatically due to state change
    }
  }

  // Process conjunct when next consonant is typed
  void _processConjunctConsonant(String newConsonant) async {
    if (!_conjunctMode || _pendingConsonant == null) return;
    
    final controller = widget.textController;
    if (controller == null) return;
    
    // Replace the pending consonant with first consonant + halant + second consonant
    final currentText = controller.text;
    
    // Find the last position of the pending consonant
    final lastConsonantIndex = currentText.lastIndexOf(_pendingConsonant!);
    if (lastConsonantIndex >= 0) {
      // Form the conjunct using native processing with automatic Dart fallback
      final conjunct = await IndicaNativeService.processConjunct(
        baseChar: _pendingConsonant!,
        consonant: newConsonant,
        language: _currentLanguage,
      );
      
      // Replace the old consonant with the conjunct
      final newText = currentText.replaceRange(
        lastConsonantIndex,
        lastConsonantIndex + _pendingConsonant!.length,
        conjunct,
      );
      
      // Update cursor position
      final newOffset = lastConsonantIndex + conjunct.length;
      
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
      
      // Reset conjunct mode
      setState(() {
        _conjunctMode = false;
        _pendingConsonant = null;
      });
      
      return; // Don't process normal input
    }
    
    // If we couldn't find the consonant, reset conjunct mode
    _resetConjunctMode();
  }

  // Reset conjunct mode
  void _resetConjunctMode() {
    if (_conjunctMode) {
      setState(() {
        _conjunctMode = false;
        _pendingConsonant = null;
      });
    }
  }

  // Get current layout based on language, page, and selected letter
  List<List<String>> _getCurrentLayout() {
    // Use cached layout if available and valid
    if (!_layoutCacheInvalid && _cachedCurrentLayout != null) {
      return _cachedCurrentLayout!;
    }
    
    List<List<String>> layout;
    if (_showNumericKeyboard) {
      layout = KeyboardLayout.getNumericLayout();
    } else {
      layout = KeyboardLayout.getLayoutForLanguage(
        _currentLanguage, 
        page: _currentLayoutPage,
        selectedLetter: _selectedLetter,
      );
    }
    
    // Cache the layout
    _cachedCurrentLayout = layout;
    _layoutCacheInvalid = false;
    
    return layout;
  }

  // Switch to next layout page (for non-English keyboards)
  void _switchLayoutPage() {
    if (_currentLanguage == 'en') return; // English doesn't have layout pages
    
    final maxPages = _maxLayoutPages[_currentLanguage] ?? 1;
    setState(() {
      _currentLayoutPage = (_currentLayoutPage + 1) % maxPages;
      _selectedLetter = null; // Clear selection when switching pages
      _layoutCacheInvalid = true; // Invalidate layout cache
    });
  }

  // Get layout page indicator text
  String _getLayoutPageText() {
    if (_currentLanguage == 'en') return '';
    final maxPages = _maxLayoutPages[_currentLanguage] ?? 1;
    return '${_currentLayoutPage + 1}/$maxPages';
  }

  // CRITICAL PATH: This runs on every key press - OPTIMIZED FOR ZERO LATENCY
  void _onKeyPress(String key) {
    // Handle conjunct formation for Devanagari consonants
    if (_conjunctMode && _isDevanagariConsonant(key)) {
      _processConjunctConsonant(key);
      widget.onKeyPressed?.call(key);
      return; // Don't process normal input
    }
    
    // Reset conjunct mode on any other key press
    if (_conjunctMode) {
      _resetConjunctMode();
    }
    
    // PERFORMANCE: Remove try-catch from critical path
    // Handle three-state capitalization inline for speed
    final shouldUpperCase = _isUpperCase && key.length == 1 && key.toLowerCase() != key.toUpperCase();
    final shouldAutoCapitalize = !_isUpperCase && _shouldCapitalize() && key.length == 1 && key.toLowerCase() != key.toUpperCase();
    final finalKey = shouldUpperCase ? key.toUpperCase() : (shouldAutoCapitalize ? key.toUpperCase() : key);
    
    // PERFORMANCE: Batch state updates to minimize rebuilds
    bool needsStateUpdate = false;
    if (_shiftState == ShiftState.single && shouldUpperCase) {
      _shiftState = ShiftState.off;
      needsStateUpdate = true;
    }
    
    // Handle auto-capitalization state tracking
    if (shouldAutoCapitalize) {
      _justUsedAutoCapitalization = true;
      needsStateUpdate = true;
    } else if (key.length == 1) {
      if (key.toLowerCase() != key.toUpperCase()) {
        // Reset auto-capitalization flag when typing any letter (not punctuation)
        if (_justUsedAutoCapitalization) {
          _justUsedAutoCapitalization = false;
          needsStateUpdate = true;
        }
      } else if (key == '.' || key == '!' || key == '?') {
        // Reset auto-capitalization flag when typing sentence-ending punctuation
        // so it can work for the next sentence
        if (_justUsedAutoCapitalization) {
          _justUsedAutoCapitalization = false;
          needsStateUpdate = true;
        }
      }
    }
    
    // Send text immediately (don't await)
    _handleTextInput(finalKey);
    widget.onKeyPressed?.call(finalKey);
    
    // Update state only if needed
    if (needsStateUpdate) {
      setState(() {});
    }
  }

  void _onBackspace() {
    _handleTextInput('⌫');
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
    if (mounted && language != _currentLanguage) { // Avoid unnecessary updates
      setState(() {
        _currentLanguage = language;
        _currentLayoutPage = 0; // Reset to first page when switching languages
        _selectedLetter = null; // Clear selection when switching languages
        _layoutCacheInvalid = true; // Invalidate layout cache
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
    // Check if auto-capitalization is active (should show as enabled)
    final isAutoCapActive = _currentLanguage == 'en' && _shouldCapitalize();
    
    switch (shiftState) {
      case ShiftState.capsLock:
        return 'packages/indica_keyboard/assets/icons/caps-lock-hold.svg'; // Caps lock enabled
      case ShiftState.single:
        return 'packages/indica_keyboard/assets/icons/caps-lock-enabled.svg'; // Single tap - hold state
      case ShiftState.off:
        // Show as enabled if auto-capitalization is active, otherwise off
        return isAutoCapActive 
          ? 'packages/indica_keyboard/assets/icons/caps-lock-enabled.svg'
          : 'packages/indica_keyboard/assets/icons/default-caps-lock-off.svg';
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
    
    return Column(
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
    
    return Column(
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

        if (_currentLanguage != 'en')
        Expanded(
          flex: 2,
          child: _buildKey('\u0964', keyHeight), // Spacer for balanced layout
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

        if (_currentLanguage != 'en')
        Expanded(
          flex: 2,
          child: _buildConjunctKey(keyHeight), // Conjunct formation key
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
    // PERFORMANCE: Pre-compute case conversion
    final shouldUpperCase = _isUpperCase && key.length == 1 && key.toLowerCase() != key.toUpperCase();
    final shouldAutoCapitalize = _shouldCapitalize() && key.length == 1 && key.toLowerCase() != key.toUpperCase();
    final displayKey = (shouldUpperCase || shouldAutoCapitalize) ? key.toUpperCase() : key;
    
    // PERFORMANCE: Use cached text style if available
    final textStyle = _cachedTextStyles[keyHeight.toString()] ?? TextStyle(
      fontSize: (keyHeight * 0.4).clamp(12.0, 18.0),
      fontWeight: FontWeight.normal,
      color: widget.textColor ?? KeyboardConstants.keyText,
    );
    
    return RepaintBoundary( // PERFORMANCE: Prevent unnecessary repaints
      child: SizedBox(
      height: keyHeight,
      child: Material(
        color: widget.keyColor ?? KeyboardConstants.keyBackground,
        borderRadius: _keyBorderRadius, // Use pre-computed constant
        elevation: 1,
        child: InkWell(
          onTap: () => _onKeyPress(displayKey),
          borderRadius: _keyBorderRadius, // Use pre-computed constant
          splashColor: KeyboardConstants.keySplashWithAlpha,
          highlightColor: KeyboardConstants.keyHighlightWithAlpha,
          child: Container(
            decoration: _cachedDecorations['key'], // Use cached decoration
            child: Center(
              child: Text(
                displayKey,
                style: textStyle, // Use cached/pre-computed style
              ),
            ),
          ),
        ),
      ),
    ),); // RepaintBoundary
  }

  Widget _buildSpecialKey(String label, {VoidCallback? onTap, double? keyHeight}) {
    return SizedBox(
      height: keyHeight,
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
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
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
    
    return SizedBox(
      height: keyHeight,
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
                colorFilter: (_shiftState == ShiftState.off && !(_currentLanguage == 'en' && _shouldCapitalize()))
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
    return SizedBox(
      height: keyHeight,
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

  Widget _buildConjunctKey(double keyHeight) {
    return SizedBox(
      height: keyHeight,
      child: Material(
        color: KeyboardConstants.keyBackground,
        // _conjunctMode 
        //     ? _getEffectivePrimaryColor().withValues(alpha: 0.2) // Highlight when active
        //     : KeyboardConstants.specialKeyDefault,
        borderRadius: BorderRadius.circular(6),
        elevation: 1,
        child: InkWell(
          onTap: _handleConjunctFormation,
          borderRadius: BorderRadius.circular(6),
          splashColor: KeyboardConstants.specialKeySplashWithAlpha,
          highlightColor: KeyboardConstants.specialKeyHighlightWithAlpha,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _conjunctMode 
                    ? _getEffectivePrimaryColor() 
                    : KeyboardConstants.specialKeyBorder,
                width: _conjunctMode ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: (keyHeight * 0.4).clamp(12.0, 18.0),
                  color: _conjunctMode 
                      ? _getEffectivePrimaryColor() 
                      : KeyboardConstants.textOnLight,
                  fontWeight: _conjunctMode ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}