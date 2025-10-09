import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/keyboard_layout.dart';
import '../constants/keyboard_constants.dart';
import '../constants/performance_constants.dart';
import '../services/indica_native_service.dart';

// Enum for three-state shift key behavior
enum ShiftState {
  off, // lowercase
  single, // capitalize next letter only
  capsLock, // all letters capitalized
}



/// Main Indica keyboard widget based on MinimalExamKeyboard
class IndicaKeyboard extends StatefulWidget {
  final List<String> supportedLanguages; // e.g., ['en', 'hi', 'mr']
  final TextEditingController?
  textController; // Text controller for input handling
  final FocusNode? focusNode; // Focus node for keyboard visibility management
  final Function(bool)?
  onKeyboardVisibilityChanged; // Callback for keyboard visibility changes
  final Function(String)?
  onTextInput; // Optional fallback for non-native platforms
  final bool useNativeKeyboard; // Enable/disable native integration
  final Function(bool)?
  onDialogStateChanged; // Notify parent about dialog state
  final String initialLanguage;
  final String? currentLanguage;
  final Function(String)? onLanguageChanged;
  final Function(String)? onKeyPressed;
  final double? height;
  final Color? backgroundColor;
  final Color? keyColor;
  final Color? textColor;
  final Color? primaryColor;
  final bool showLanguageSwitcher;
  final bool enableHapticFeedback;
  final bool
  autoManageKeyboardVisibility; // Auto show/hide keyboard based on focus

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
    this.currentLanguage,
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

  // 🚀 PERFORMANCE: ValueNotifiers for granular rebuilds
  late final ValueNotifier<ShiftState> _shiftStateNotifier;
  late final ValueNotifier<bool> _conjunctModeNotifier;
  late final ValueNotifier<int> _layoutPageNotifier;
  late final ValueNotifier<bool> _showNumericNotifier;
  
  // 🚀 PERFORMANCE: Cached expensive computations
  bool? _cachedShouldCapitalize;
  String? _cachedControllerText;
  double? _cachedKeyboardHeight;

  // Conjunct consonant formation state
  bool _conjunctMode = false; // Whether conjunct formation is active
  String? _pendingConsonant; // The consonant waiting to be joined

  // Auto-capitalization state (English only)
  final bool _shouldAutoCapitalize =
      true; // Start with capital for first letter
  bool _justUsedAutoCapitalization = false; // Track if we just auto-capitalized

  // Performance optimizations: Cache frequently accessed values
  late final Map<String, TextStyle> _cachedTextStyles = {};
  late final Map<String, BoxDecoration> _cachedDecorations = {};
  List<List<String>>? _cachedCurrentLayout;
  bool _layoutCacheInvalid = true;

  // Layout page management for non-English keyboards
  int _currentLayoutPage = 0;
  final Map<String, int> _maxLayoutPages = {
    'hi': 4,
    'mr': 4,
  }; // Hindi and Marathi have 4 pages

  // Selected letter for dynamic top row (vowel attachments)
  String? _selectedLetter;

  // Three-state shift key management (only for English)
  ShiftState _shiftState = ShiftState.off;
  bool get _isUpperCase =>
      _shiftState != ShiftState.off && _currentLanguage == 'en';

  bool _showNumericKeyboard = false;

  // Double tap detection for caps lock
  DateTime? _lastShiftTap;
  static const doubleTapThreshold = Duration(milliseconds: 300);

  // Performance: Pre-computed constants
  static const _keyBorderRadius = BorderRadius.all(Radius.circular(6));

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.currentLanguage ?? widget.initialLanguage;

    // 🚀 PERFORMANCE: Initialize ValueNotifiers for granular updates
    _shiftStateNotifier = ValueNotifier(_shiftState);
    _conjunctModeNotifier = ValueNotifier(_conjunctMode);
    _layoutPageNotifier = ValueNotifier(_currentLayoutPage);
    _showNumericNotifier = ValueNotifier(_showNumericKeyboard);

    // Initialize native service for automatic high-performance processing
    IndicaNativeService.initialize();

    // Initialize focus node (use provided one or create internal)
    _internalFocusNode = widget.focusNode ?? FocusNode();

    // Set up focus listener for automatic keyboard visibility management
    if (widget.autoManageKeyboardVisibility) {
      _internalFocusNode.addListener(_handleFocusChange);
    }

    // 🚀 PERFORMANCE: Optimized text controller listener with debouncing
    if (widget.textController != null) {
      widget.textController!.addListener(_onTextControllerChange);
    }

    _loadKeyboardLayouts();

    // Performance: Pre-warm all caches for zero-latency access
    KeyboardLayout.preWarmAllCaches();
  }

  @override
  void didUpdateWidget(IndicaKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle external language changes via currentLanguage parameter
    if (widget.currentLanguage != null && 
        widget.currentLanguage != oldWidget.currentLanguage &&
        widget.currentLanguage != _currentLanguage) {
      // 🚀 PERFORMANCE: Use ValueNotifiers for granular updates
      _currentLanguage = widget.currentLanguage!;
      _currentLayoutPage = 0; // Reset to first page when switching languages
      _selectedLetter = null; // Clear selection when switching languages
      _layoutCacheInvalid = true; // Invalidate layout cache
      
      // Reset conjunct mode when switching languages
      if (_conjunctMode) {
        _conjunctMode = false;
        _pendingConsonant = null;
        _conjunctModeNotifier.value = false;
      }
      
      // Update ValueNotifiers for UI consistency
      _layoutPageNotifier.value = _currentLayoutPage;
      
      // Note: We don't call widget.onLanguageChanged here to avoid circular updates
    }
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

  // 🚀 PERFORMANCE: Optimized text controller change handler with caching
  void _onTextControllerChange() {
    if (!mounted || _currentLanguage != 'en' || !_shouldAutoCapitalize) return;
    
    final currentText = widget.textController?.text;
    if (currentText == _cachedControllerText) return; // No change, skip
    
    _cachedControllerText = currentText;
    
    // Update auto-capitalization state (this may reset _justUsedAutoCapitalization)
    _updateAutoCapitalizationState();
    
    _cachedShouldCapitalize = null; // Invalidate cache
    
    // Only rebuild if capitalization state actually changed  
    final oldValue = _cachedShouldCapitalize ?? false;
    final newShouldCapitalize = _shouldCapitalize(); // Use direct call for UI updates
    if (newShouldCapitalize != oldValue) {
      // Use setState for auto-capitalization since it affects whole keyboard
      setState(() {});
    }
  }

  // 🚀 PERFORMANCE: Cached version of _shouldCapitalize to avoid expensive recalculations
  bool _shouldCapitalizeCached() {
    if (_cachedShouldCapitalize != null && 
        widget.textController?.text == _cachedControllerText) {
      return _cachedShouldCapitalize!;
    }
    
    final result = _shouldCapitalize();
    _cachedShouldCapitalize = result;
    _cachedControllerText = widget.textController?.text;
    return result;
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

      // Validate selection bounds for backspace
      if (currentText.isNotEmpty && 
          selection.start > 0 && 
          selection.start <= currentText.length) {
        // Delete character before cursor
        final newText = currentText.replaceRange(
          selection.start - 1,
          selection.start,
          '',
        );
        final newOffset = (selection.start - 1).clamp(0, newText.length);

        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
        );
      }
    } else {
      // Handle regular text input at cursor position
      final currentText = controller.text;
      final selection = controller.selection;
      
      // Validate selection bounds for text input
      final safeStart = selection.start.clamp(0, currentText.length);
      final safeEnd = selection.end.clamp(safeStart, currentText.length);
      
      final newText = currentText.replaceRange(
        safeStart,
        safeEnd,
        text,
      );
      final newOffset = (safeStart + text.length).clamp(0, newText.length);

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
    // 🚀 PERFORMANCE: Dispose ValueNotifiers to prevent memory leaks
    _shiftStateNotifier.dispose();
    _conjunctModeNotifier.dispose();
    _layoutPageNotifier.dispose();
    _showNumericNotifier.dispose();
    
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

  // Helper method to detect if we're at the start of a new sentence
  bool _isAtSentenceStart(String text) {
    if (text.isEmpty) return true; // Start of text
    
    // Pattern 1: Text ends with sentence punctuation followed by one or more spaces
    // This is the most common case: "Hello. " <- cursor is after space, ready for new sentence
    final regex = RegExp(r'[.!?]\s+$');
    if (regex.hasMatch(text)) {
      return true;
    }
    
    // Pattern 2: Text ends with sentence punctuation and cursor is right after it
    // This handles: "Hello." <- cursor is right after period
    if (text.isNotEmpty) {
      final lastChar = text[text.length - 1];
      if (lastChar == '.' || lastChar == '!' || lastChar == '?') {
        return true;
      }
    }
    
    return false;
  }

  // Helper method to determine if next character should be capitalized
  bool _shouldCapitalize() {
    if (_currentLanguage != 'en' || !_shouldAutoCapitalize) return false;

    final controller = widget.textController;
    if (controller == null) return false; // No controller, no capitalization

    final currentText = controller.text;
    if (currentText.isEmpty) return true; // Start of text

    // Check if we're at the beginning of a sentence
    final isAtSentenceStart = _isAtSentenceStart(currentText);
    
    // Return true if at sentence start and haven't used auto-cap for this sentence
    return isAtSentenceStart && !_justUsedAutoCapitalization;
  }
  
  // Helper method to update auto-capitalization state based on text changes
  void _updateAutoCapitalizationState() {
    if (_currentLanguage != 'en' || !_shouldAutoCapitalize) return;
    
    final currentText = widget.textController?.text ?? '';
    final isAtSentenceStart = _isAtSentenceStart(currentText);
    
    // Reset the flag if we're at a new sentence boundary
    if (isAtSentenceStart && _justUsedAutoCapitalization) {
      _justUsedAutoCapitalization = false;
      _cachedShouldCapitalize = null; // Invalidate cache
    }
  }

  // Handle conjunct formation logic - toggle on/off
  void _handleConjunctFormation() {
    if (_currentLanguage == 'en') return; // No conjunct for English

    // If already in conjunct mode, toggle it off
    if (_conjunctMode) {
      _conjunctMode = false;
      _pendingConsonant = null;
      _conjunctModeNotifier.value = false; // Use ValueNotifier
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
      _conjunctMode = true;
      _pendingConsonant = beforeCursor;
      _conjunctModeNotifier.value = true; // Use ValueNotifier

      // Visual feedback - the button will highlight automatically due to ValueNotifier change
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
      _conjunctMode = false;
      _pendingConsonant = null;
      _conjunctModeNotifier.value = false; // Update ValueNotifier for UI consistency

      return; // Don't process normal input
    }

    // If we couldn't find the consonant, reset conjunct mode
    _resetConjunctMode();
    return; // Don't process the key normally if conjunct processing failed
  }

  // Reset conjunct mode
  // 🚀 PERFORMANCE: Reset conjunct mode with ValueNotifier
  void _resetConjunctMode() {
    if (_conjunctMode) {
      _conjunctMode = false;
      _pendingConsonant = null;
      _conjunctModeNotifier.value = false; // Use ValueNotifier
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

  // 🚀 PERFORMANCE: Use ValueNotifier for layout page switching
  void _switchLayoutPage() {
    if (_currentLanguage == 'en') return; // English doesn't have layout pages

    final maxPages = _maxLayoutPages[_currentLanguage] ?? 1;
    _currentLayoutPage = (_currentLayoutPage + 1) % maxPages;
    _selectedLetter = null; // Clear selection when switching pages
    _layoutCacheInvalid = true; // Invalidate layout cache
    _layoutPageNotifier.value = _currentLayoutPage; // Granular update
  }

  // Get layout page indicator text
  String _getLayoutPageText() {
    if (_currentLanguage == 'en') return '';
    final maxPages = _maxLayoutPages[_currentLanguage] ?? 1;
    return '${_currentLayoutPage + 1}/$maxPages';
  }

  // 🚀 CRITICAL PATH: ULTRA-OPTIMIZED for zero-latency typing
  void _onKeyPress(String key) {
    // Fast path: Handle conjunct formation for Devanagari consonants
    if (_conjunctMode && _isDevanagariConsonant(key)) {
      _processConjunctConsonant(key);
      widget.onKeyPressed?.call(key);
      return; // Early return - no state updates needed
    }

    // Fast path: Reset conjunct mode (ValueNotifier update, not setState)
    if (_conjunctMode) {
      _conjunctMode = false;
      _pendingConsonant = null;
      _conjunctModeNotifier.value = false; // Granular update
    }

    // 🚀 PERFORMANCE: Pre-compute expensive checks once
    final isLetter = key.length == 1 && key.toLowerCase() != key.toUpperCase();
    final shouldUpperCase = _isUpperCase && isLetter;
    final shouldAutoCapitalize = !_isUpperCase && isLetter && _shouldCapitalizeCached();
    
    // Fast string conversion (avoid multiple toUpperCase calls)
    final finalKey = (shouldUpperCase || shouldAutoCapitalize) ? key.toUpperCase() : key;

    // 🚀 PERFORMANCE: Micro-batched state updates with ValueNotifiers
    bool needsShiftUpdate = false;
    if (_shiftState == ShiftState.single && shouldUpperCase) {
      _shiftState = ShiftState.off;
      needsShiftUpdate = true;
    }

    // Cache invalidation for auto-capitalization
    bool shouldUpdateAutoCapState = false;
    if (shouldAutoCapitalize) {
      _justUsedAutoCapitalization = true;
      _cachedShouldCapitalize = null; // Invalidate cache
      shouldUpdateAutoCapState = true;
    } else if (isLetter || key == '.' || key == '!' || key == '?') {
      if (_justUsedAutoCapitalization) {
        _justUsedAutoCapitalization = false;
        _cachedShouldCapitalize = null; // Invalidate cache
        shouldUpdateAutoCapState = true;
      }
    }

    // 🚀 PERFORMANCE: Send text immediately without awaiting any UI updates
    _handleTextInput(finalKey);
    widget.onKeyPressed?.call(finalKey);
    
    // Track performance and trigger cleanup if needed
    PerformanceUtils.onKeyPress();

    // 🚀 PERFORMANCE: Use ValueNotifier for shift key updates (avoids full setState)
    if (needsShiftUpdate) {
      _shiftStateNotifier.value = _shiftState;
    }
    
    // Update auto-capitalization state with setState since it affects whole keyboard
    if (shouldUpdateAutoCapState) {
      setState(() {});
    }
  }

  void _onBackspace() {
    _handleTextInput('⌫');
  }

  // 🚀 PERFORMANCE: Optimized _toggleCase with ValueNotifier updates
  void _toggleCase() {
    if (_currentLanguage == 'en') {
      // Handle shift key for English
      final now = DateTime.now();
      final isAutoCapActive = _shouldCapitalizeCached();
      
      if (_lastShiftTap != null &&
          now.difference(_lastShiftTap!) < doubleTapThreshold) {
        // Double tap: activate caps lock
        _shiftState = ShiftState.capsLock;
        // When user manually activates caps lock, disable auto-capitalization
        if (isAutoCapActive) {
          _justUsedAutoCapitalization = true;
          _cachedShouldCapitalize = null; // Invalidate cache
        }
        _shiftStateNotifier.value = _shiftState; // Update ValueNotifier
      } else {
        // Single tap: cycle through states with auto-capitalization awareness
        switch (_shiftState) {
          case ShiftState.off:
            // If auto-capitalization is active and user clicks the "active" shift key,
            // they expect to turn off capitalization, so disable auto-cap and keep shift off
            if (isAutoCapActive) {
              _justUsedAutoCapitalization = true; // Disable auto-cap for this context
              _cachedShouldCapitalize = null; // Invalidate cache
            } else {
              _shiftState = ShiftState.single;
            }
            break;
          case ShiftState.single:
          case ShiftState.capsLock:
            _shiftState = ShiftState.off;
            break;
        }
        _shiftStateNotifier.value = _shiftState; // Update ValueNotifier
      }
      _lastShiftTap = now;
      // Update auto-capitalization UI when shift state changes
      setState(() {});
    } else {
      // Handle layout page switching for non-English keyboards
      _switchLayoutPage();
    }
  }

  // 🚀 PERFORMANCE: Use ValueNotifier instead of setState for keyboard toggle
  void _toggleNumericKeyboard() {
    _showNumericKeyboard = !_showNumericKeyboard;
    _showNumericNotifier.value = _showNumericKeyboard;
    _layoutCacheInvalid = true; // Invalidate layout cache
  }

  void _toggleLanguageSelector() {
    if (widget.supportedLanguages.length > 1) {
      _showLanguageModal();
    }
  }

  void _switchLanguage(String language) {
    if (mounted && language != _currentLanguage) {
      // Avoid unnecessary updates
      setState(() {
        _currentLanguage = language;
        _currentLayoutPage = 0; // Reset to first page when switching languages
        _selectedLetter = null; // Clear selection when switching languages
        _layoutCacheInvalid = true; // Invalidate layout cache
        
        // Reset conjunct mode when switching languages
        if (_conjunctMode) {
          _conjunctMode = false;
          _pendingConsonant = null;
          _conjunctModeNotifier.value = false;
        }
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
    final isAutoCapActive = _currentLanguage == 'en' && _shouldCapitalizeCached();

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
    return widget.primaryColor?.withValues(alpha: 0.1) ??
        KeyboardConstants.primaryLight;
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

  /// 🎹 Build expandable alpha keyboard that fills the given height optimally
  Widget _buildExpandableAlphaKeyboardLayout(double totalKeyboardHeight) {
    // 🚀 PERFORMANCE: Listen to layout page changes for multi-page languages
    return ValueListenableBuilder<int>(
      valueListenable: _layoutPageNotifier,
      builder: (context, currentLayoutPage, child) {
        return _buildAlphaKeyboardContent(totalKeyboardHeight);
      },
    );
  }

  /// Build the actual alpha keyboard content
  Widget _buildAlphaKeyboardContent(double totalKeyboardHeight) {
    final layout = _getCurrentLayout();

    // 🎯 Calculate key height to perfectly fill available space
    const double padding = 8.0; // Total padding from container
    final int layoutRows = layout.length; // Dynamic based on layout array length
    final int totalRows = layoutRows + 1; // Layout rows + 1 unified bottom row

    // 🔧 Keys expand to fill the exact keyboard height (no waste space)
    final double optimalKeyHeight = (totalKeyboardHeight - padding) / totalRows;
    
    // Safety clamps to ensure usability (but prioritize filling space)
    const double minKeyHeight = 25.0; // Absolute minimum for tapping
    const double maxKeyHeight = 60.0; // Maximum for comfort
    final double expandedKeyHeight = optimalKeyHeight.clamp(minKeyHeight, maxKeyHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Build all layout rows dynamically - keys expand to fill space
        ...layout.asMap().entries.map((entry) {
          final int index = entry.key;
          final List<String> row = entry.value;
          final bool isLastRow = index == layout.length - 1;

          return Flexible(
            child: isLastRow
                // Last row uses buildBottomRow for shift and backspace functionality
                ? _buildBottomRow(row, expandedKeyHeight)
                // All other rows use regular buildKeyRow
                : _buildKeyRow(row, expandedKeyHeight),
          );
        }),

        // Unified bottom row (spacebar, etc.)
        Flexible(child: _buildAdaptiveUnifiedBottomRow(expandedKeyHeight)),
      ],
    );
  }

  /// 🎹 Build expandable numeric keyboard that fills the given height optimally
  Widget _buildExpandableNumericKeyboardLayout(double totalKeyboardHeight) {
    final layout = KeyboardLayout.getNumericLayout();

    // 🎯 Calculate key height to perfectly fill available space
    const double padding = 8.0; // Total padding from container
    final int layoutRows = layout.length; // Dynamic based on layout array length
    final int totalRows = layoutRows + 1; // Layout rows + 1 unified bottom row

    // 🔧 Keys expand to fill the exact keyboard height (no waste space)
    final double optimalKeyHeight = (totalKeyboardHeight - padding) / totalRows;
    
    // Safety clamps to ensure usability (but prioritize filling space)
    const double minKeyHeight = 25.0; // Absolute minimum for tapping
    const double maxKeyHeight = 60.0; // Maximum for comfort
    final double expandedKeyHeight = optimalKeyHeight.clamp(minKeyHeight, maxKeyHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Build all layout rows dynamically - keys expand to fill space
        ...layout.asMap().entries.map((entry) {
          final int index = entry.key;
          final List<String> row = entry.value;
          final bool isLastRow = index == layout.length - 1;

          return Flexible(
            child: isLastRow
                // Last row uses buildNumericBottomRow for special handling
                ? _buildNumericBottomRow(row, expandedKeyHeight)
                // All other rows use regular buildKeyRow
                : _buildKeyRow(row, expandedKeyHeight),
          );
        }),

        // Unified bottom row (spacebar, etc.)
        Flexible(child: _buildAdaptiveUnifiedBottomRow(expandedKeyHeight)),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys, double keyHeight) {
    return Row(
      children: keys.map((key) {
        return Expanded(child: _buildKey(key, keyHeight));
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
          return Expanded(child: _buildKey(key, keyHeight));
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
        // Regular symbol keys
        ...keys.map((key) {
          return Expanded(child: _buildKey(key, keyHeight));
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
        Expanded(flex: 2, child: _buildKey(',', keyHeight)),

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
              onLongPress: widget.showLanguageSwitcher
                  ? _toggleLanguageSelector
                  : null,
              borderRadius: BorderRadius.circular(6),
              splashColor: KeyboardConstants.keySplashWithAlpha,
              highlightColor: KeyboardConstants.keyHighlightWithAlpha,
              child: Container(
                height: keyHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: KeyboardConstants.keyBorder,
                    width: 1,
                  ),
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
        Expanded(flex: 2, child: _buildKey('.', keyHeight)),

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

  // 🚀 PERFORMANCE: Optimized _buildKey with ValueListenableBuilder for capitalization
  Widget _buildKey(String key, double keyHeight) {
    // Only use ValueListenableBuilder for letters that can be capitalized
    final isLetter = key.length == 1 && key.toLowerCase() != key.toUpperCase();
    
    if (!isLetter) {
      // Non-letters don't need capitalization logic
      return _buildStaticKey(key, keyHeight);
    }
    
    // Letters need to respond to shift state changes
    return ValueListenableBuilder<ShiftState>(
      valueListenable: _shiftStateNotifier,
      builder: (context, shiftState, child) {
        final shouldUpperCase = shiftState != ShiftState.off && _currentLanguage == 'en';
        final shouldAutoCapitalize = !shouldUpperCase && _shouldCapitalize(); // Fixed: Use direct call for display
        final displayKey = (shouldUpperCase || shouldAutoCapitalize) ? key.toUpperCase() : key;
        
        return _buildKeyWithHandler(displayKey, key, keyHeight);
      },
    );
  }

  // 🚀 PERFORMANCE: Key builder with separate display and press logic
  Widget _buildKeyWithHandler(String displayKey, String pressKey, double keyHeight) {
    // PERFORMANCE: Use cached text style if available
    final textStyle =
        _cachedTextStyles[keyHeight.toString()] ??
        TextStyle(
          fontSize: (keyHeight * 0.4).clamp(12.0, 18.0),
          fontWeight: FontWeight.normal,
          color: widget.textColor ?? KeyboardConstants.keyText,
        );

    return RepaintBoundary(
      // PERFORMANCE: Prevent unnecessary repaints
      child: SizedBox(
        height: keyHeight,
        child: Material(
          color: widget.keyColor ?? KeyboardConstants.keyBackground,
          borderRadius: _keyBorderRadius, // Use pre-computed constant
          elevation: 1,
          child: InkWell(
            onTap: () => _onKeyPress(pressKey), // Press the original key
            borderRadius: _keyBorderRadius, // Use pre-computed constant
            splashColor: KeyboardConstants.keySplashWithAlpha,
            highlightColor: KeyboardConstants.keyHighlightWithAlpha,
            child: Container(
              decoration: _cachedDecorations['key'], // Use cached decoration
              child: Center(
                child: Text(
                  displayKey, // Display the capitalized version
                  style: textStyle, // Use cached/pre-computed style
                ),
              ),
            ),
          ),
        ),
      ),
    ); // RepaintBoundary
  }

  // 🚀 PERFORMANCE: Static key builder (no state dependencies)
  Widget _buildStaticKey(String key, double keyHeight) {

    // PERFORMANCE: Use cached text style if available
    final textStyle =
        _cachedTextStyles[keyHeight.toString()] ??
        TextStyle(
          fontSize: (keyHeight * 0.4).clamp(12.0, 18.0),
          fontWeight: FontWeight.normal,
          color: widget.textColor ?? KeyboardConstants.keyText,
        );

    return RepaintBoundary(
      // PERFORMANCE: Prevent unnecessary repaints
      child: SizedBox(
        height: keyHeight,
        child: Material(
          color: widget.keyColor ?? KeyboardConstants.keyBackground,
          borderRadius: _keyBorderRadius, // Use pre-computed constant
          elevation: 1,
          child: InkWell(
            onTap: () => _onKeyPress(key),
            borderRadius: _keyBorderRadius, // Use pre-computed constant
            splashColor: KeyboardConstants.keySplashWithAlpha,
            highlightColor: KeyboardConstants.keyHighlightWithAlpha,
            child: Container(
              decoration: _cachedDecorations['key'], // Use cached decoration
              child: Center(
                child: Text(
                  key,
                  style: textStyle, // Use cached/pre-computed style
                ),
              ),
            ),
          ),
        ),
      ),
    ); // RepaintBoundary
  }

  Widget _buildSpecialKey(
    String label, {
    VoidCallback? onTap,
    double? keyHeight,
  }) {
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
                width: 1,
              ),
            ),
            child: Center(
              child: FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize:
                        (keyHeight != null
                                ? (keyHeight * 0.35).toDouble()
                                : 16.0)
                            .clamp(10.0, 16.0),
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

  // 🚀 PERFORMANCE: Optimized shift key with ValueListenableBuilder
  Widget _buildShiftKey(double keyHeight) {
    return ValueListenableBuilder<ShiftState>(
      valueListenable: _shiftStateNotifier,
      builder: (context, shiftState, child) {
        final iconPath = _getShiftIconPath(shiftState);
        final shouldAutoCapitalize = _shouldCapitalize(); // Fixed: Use direct call to avoid cache issues

            return RepaintBoundary(
              child: SizedBox(
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
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          iconPath,
                          width: shiftState == ShiftState.capsLock ? 12 : 8,
                          height: shiftState == ShiftState.capsLock ? 12 : 8,
                          colorFilter:
                              (shiftState == ShiftState.off && !shouldAutoCapitalize)
                              ? ColorFilter.mode(Colors.black26, BlendMode.srcIn)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
      },
    );
  }

  // 🚀 PERFORMANCE: Optimized layout switcher key with ValueListenableBuilder
  Widget _buildLayoutSwitcherKey(double keyHeight) {
    return ValueListenableBuilder<int>(
      valueListenable: _layoutPageNotifier,
      builder: (context, currentLayoutPage, child) {
        return RepaintBoundary(
          child: SizedBox(
            height: keyHeight,
            child: Material(
              color: KeyboardConstants.specialKeyDefault,
              borderRadius: BorderRadius.circular(6),
              elevation: 1,
              child: InkWell(
                onTap: _switchLayoutPage, // Fixed: was calling _toggleCase instead!
                borderRadius: BorderRadius.circular(6),
                splashColor: KeyboardConstants.specialKeySplashWithAlpha,
                highlightColor: KeyboardConstants.specialKeyHighlightWithAlpha,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: KeyboardConstants.specialKeyBorder,
                      width: 1,
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
          ),
        );
      },
    );
  }

  // 🚀 PERFORMANCE: Optimized conjunct key with ValueListenableBuilder
  Widget _buildConjunctKey(double keyHeight) {
    return ValueListenableBuilder<bool>(
      valueListenable: _conjunctModeNotifier,
      builder: (context, isConjunctMode, child) {
        return RepaintBoundary(
          child: SizedBox(
            height: keyHeight,
            child: Material(
              color: KeyboardConstants.keyBackground,
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
                      color: isConjunctMode
                          ? _getEffectivePrimaryColor()
                          : KeyboardConstants.specialKeyBorder,
                      width: isConjunctMode ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: (keyHeight * 0.4).clamp(12.0, 18.0),
                        color: isConjunctMode
                            ? _getEffectivePrimaryColor()
                            : KeyboardConstants.textOnLight,
                        fontWeight: isConjunctMode ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final viewInsets = mediaQuery.viewInsets;
    final viewPadding = mediaQuery.viewPadding;
    final isLandscape = screenSize.width > screenSize.height;

    // 🚀 PERFORMANCE: Cache keyboard height to avoid expensive recalculations
    final heightCacheKey = '${screenSize.width}_${screenSize.height}_${viewInsets.bottom}_$isLandscape';
    if (_cachedKeyboardHeight == null || _cachedControllerText != heightCacheKey) {
      _cachedKeyboardHeight = _calculateSystemProportionHeight(
        screenSize: screenSize,
        viewInsets: viewInsets,
        viewPadding: viewPadding,
        isLandscape: isLandscape,
      );
      _cachedControllerText = heightCacheKey; // Reuse cache field for height key
    }
    final optimalKeyboardHeight = _cachedKeyboardHeight!;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: widget.height ?? optimalKeyboardHeight,
        minHeight: 0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? KeyboardConstants.keyboardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: _buildExpandableKeyboardLayout(widget.height ?? optimalKeyboardHeight),
      ),
    );
  }

  /// 🎹 Calculate keyboard height using system keyboard proportions
  /// Detects actual system keyboard when visible, otherwise uses optimal proportions
  double _calculateSystemProportionHeight({
    required Size screenSize,
    required EdgeInsets viewInsets,
    required EdgeInsets viewPadding,
    required bool isLandscape,
  }) {
    // Get available screen height (excluding system UI)
    final availableHeight = screenSize.height - viewPadding.top - viewPadding.bottom;
    
    // 🎯 Priority 1: Use actual system keyboard height if visible
    final systemKeyboardHeight = viewInsets.bottom;
    final isSystemKeyboardVisible = systemKeyboardHeight > 50;
    
    if (isSystemKeyboardVisible) {
      // Use system keyboard height as the gold standard for proportions
      return systemKeyboardHeight.clamp(200.0, availableHeight * 0.7);
    }
    
    // 🎯 Priority 2: Use platform-specific optimal proportions based on research
    return _getOptimalKeyboardProportion(
      availableHeight: availableHeight,
      screenSize: screenSize,
      isLandscape: isLandscape,
    );
  }

  /// 🎹 Get optimal keyboard proportion based on system keyboard research
  /// Uses iOS/Android system keyboard proportions as the gold standard
  double _getOptimalKeyboardProportion({
    required double availableHeight,
    required Size screenSize,
    required bool isLandscape,
  }) {
    // Research-based system keyboard proportions
    // iOS: ~35-40% portrait, ~50-55% landscape
    // Android: ~38-42% portrait, ~52-58% landscape
    
    // Detect device type for optimal proportions
    final shortestSide = screenSize.shortestSide;
    final isTablet = shortestSide >= 600;
    final isCompact = shortestSide < 360;
    
    if (isTablet) {
      // Tablets: Smaller proportions due to larger screens
      return isLandscape 
          ? availableHeight * 0.35  // 35% in landscape
          : availableHeight * 0.30; // 30% in portrait
    } else if (isCompact) {
      // Compact phones: Standard proportions but capped
      return isLandscape
          ? availableHeight * 0.40  // 40% max in landscape as requested
          : availableHeight * 0.38; // 38% in portrait
    } else {
      // Standard phones: Use optimal system proportions
      return isLandscape
          ? availableHeight * 0.40  // 40% max in landscape as requested
          : availableHeight * 0.38; // 38% in portrait (optimal for content)
    }
  }

  /// 🎹 Build keyboard layout that expands keys to fill available height
  /// Keys dynamically size themselves to optimally use the keyboard height
  Widget _buildExpandableKeyboardLayout(double totalKeyboardHeight) {
    // 🚀 PERFORMANCE: Use ValueListenableBuilder for granular rebuilds
    return ValueListenableBuilder<bool>(
      valueListenable: _showNumericNotifier,
      builder: (context, showNumeric, child) {
        return RepaintBoundary(
          child: showNumeric
              ? _buildExpandableNumericKeyboardLayout(totalKeyboardHeight)
              : _buildExpandableAlphaKeyboardLayout(totalKeyboardHeight),
        );
      },
    );
  }
}
