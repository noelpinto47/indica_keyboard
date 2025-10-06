import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Native integration service for Indica Keyboard
/// Provides high-performance native text processing with Dart fallback
class IndicaNativeService {
  static const MethodChannel _channel = MethodChannel('indica_keyboard');
  
  static bool _nativeSupported = false;
  static bool _nativeEnabled = false;
  static bool _initialized = false;
  
  // Logging configuration
  static bool _loggingEnabled = true;
  static int _nativeCallCount = 0;
  static int _dartFallbackCount = 0;
  
  /// Enable or disable logging for native vs Dart processing
  static void setLogging(bool enabled) {
    _loggingEnabled = enabled;
  }
  
  /// Get processing statistics
  static Map<String, dynamic> getProcessingStats() {
    return {
      'nativeSupported': _nativeSupported,
      'nativeEnabled': _nativeEnabled,
      'nativeCallCount': _nativeCallCount,
      'dartFallbackCount': _dartFallbackCount,
      'totalCalls': _nativeCallCount + _dartFallbackCount,
      'nativePercentage': (_nativeCallCount + _dartFallbackCount) > 0 
          ? (_nativeCallCount / (_nativeCallCount + _dartFallbackCount) * 100).toStringAsFixed(1)
          : '0.0',
    };
  }
  
  /// Log processing method used
  static void _logProcessing(String method, bool useNative, [String? details]) {
    if (!_loggingEnabled) return;
    
    if (useNative) {
      _nativeCallCount++;
      developer.log(
        '🚀 Native processing: $method ${details ?? ""}',
        name: 'IndicaKeyboard',
        level: 800, // Info level
      );
    } else {
      _dartFallbackCount++;
      developer.log(
        '🔄 Dart fallback: $method ${details ?? ""}',
        name: 'IndicaKeyboard',
        level: 900, // Warning level
      );
    }
  }
  
  /// Initialize native service and check availability
  /// Returns true if native processing is available, false if using Dart fallback
  static Future<bool> initialize() async {
    if (_initialized) return _nativeSupported;
    
    try {
      // Check if native processing is supported
      _nativeSupported = await _channel.invokeMethod('isNativeSupported') ?? false;
      _nativeEnabled = _nativeSupported; // If supported, consider it enabled for processing
      _initialized = true;
      
      if (_loggingEnabled) {
        developer.log(
          _nativeSupported 
            ? '✅ Native Android processing initialized successfully'
            : '⚠️ Native processing unavailable, using Dart fallback',
          name: 'IndicaKeyboard',
          level: _nativeSupported ? 800 : 900,
        );
      }
      
      // Note: We don't require system IME to be enabled for native text processing
      // Native processing can work even with Dart UI keyboard
      return _nativeSupported;
    } catch (e) {
      // Fallback to Dart implementation with logging
      _nativeSupported = false;
      _nativeEnabled = false;
      _initialized = true;
      
      if (_loggingEnabled) {
        developer.log(
          '❌ Native initialization failed: $e, using Dart fallback',
          name: 'IndicaKeyboard',
          level: 1000, // Error level
        );
      }
      
      return false;
    }
  }
  
  /// Check if native processing is available
  static bool get isNativeSupported => _nativeSupported;
  
  /// Check if native keyboard is enabled in system
  static bool get isNativeEnabled => _nativeEnabled;
  
  /// Get current processing mode (for debugging/monitoring)
  static String getProcessingMode() {
    if (!_initialized) return 'Not initialized';
    return _nativeSupported ? 'Native processing' : 'Dart fallback';
  }
  
  /// Check if native processing is currently active
  static bool get isUsingNativeProcessing => _nativeSupported && _initialized;
  
  /// Process text with native performance (with automatic Dart fallback)
  /// This method is transparent - always returns processed text regardless of implementation
  static Future<String> processText({
    required String text,
    required String language,
  }) async {
    // Auto-initialize if not done yet
    if (!_initialized) {
      await initialize();
    }
    
    // Try native processing first (if available)
    if (_nativeSupported) {
      try {
        final result = await _channel.invokeMethod('processTextNative', {
          'text': text,
          'language': language,
        });
        _logProcessing('processText', true, 'language: $language');
        return result as String? ?? _processTextDart(text, language);
      } catch (e) {
        // Fallback to Dart implementation with logging
        _logProcessing('processText', false, 'native failed: $e');
      }
    } else {
      _logProcessing('processText', false, 'native not supported');
    }

    // Dart fallback implementation (always works)
    return _processTextDart(text, language);
  }
  
  /// Process conjunct with native performance (with automatic Dart fallback) 
  /// This method is transparent - always returns processed conjunct regardless of implementation
  static Future<String> processConjunct({
    required String baseChar,
    required String consonant,
    required String language,
  }) async {
    // Auto-initialize if not done yet
    if (!_initialized) {
      await initialize();
    }
    
    // Try native processing first (if available)
    if (_nativeSupported) {
      try {
        final result = await _channel.invokeMethod('processConjunctNative', {
          'base': baseChar,
          'consonant': consonant,
          'language': language,
        });
        _logProcessing('processConjunct', true, '$baseChar + $consonant');
        return result as String? ?? _processConjunctDart(baseChar, consonant, language);
      } catch (e) {
        // Fallback to Dart implementation with logging
        _logProcessing('processConjunct', false, 'native failed: $e');
      }
    } else {
      _logProcessing('processConjunct', false, 'native not supported');
    }

    // Dart fallback implementation (always works)
    return _processConjunctDart(baseChar, consonant, language);
  }
  
  /// Calculate smart delete count for Devanagari (with automatic Dart fallback)
  /// This method is transparent - always returns delete count regardless of implementation
  static Future<int> calculateDeleteCount(String textBeforeCursor) async {
    // Auto-initialize if not done yet
    if (!_initialized) {
      await initialize();
    }
    
    // Try native processing first (if available)
    if (_nativeSupported) {
      try {
        final result = await _channel.invokeMethod('calculateDeleteCountNative', {
          'text': textBeforeCursor,
        });
        _logProcessing('calculateDeleteCount', true, 'text length: ${textBeforeCursor.length}');
        return result as int? ?? _calculateDeleteCountDart(textBeforeCursor);
      } catch (e) {
        // Fallback to Dart implementation with logging
        _logProcessing('calculateDeleteCount', false, 'native failed: $e');
      }
    } else {
      _logProcessing('calculateDeleteCount', false, 'native not supported');
    }

    // Dart fallback implementation (always works)
    return _calculateDeleteCountDart(textBeforeCursor);
  }
  
  /// Get native performance statistics
  static Future<Map<String, int>> getPerformanceStats() async {
    if (!_nativeSupported) return {};
    
    try {
      final result = await _channel.invokeMethod('getNativePerformanceStats');
      return Map<String, int>.from(result as Map? ?? {});
    } catch (e) {
      return {};
    }
  }
  
  /// Clear native caches for memory management
  static Future<bool> clearNativeCaches() async {
    if (!_nativeSupported) return false;
    
    try {
      final result = await _channel.invokeMethod('clearNativeCaches');
      return result == true;
    } catch (e) {
      return false;
    }
  }
  
  // Dart fallback implementations
  static String _processTextDart(String text, String language) {
    switch (language) {
      case 'hi':
      case 'mr':
        return _processDevanagariTextDart(text);
      case 'en':
        return _processEnglishTextDart(text);
      default:
        return text;
    }
  }
  
  static String _processDevanagariTextDart(String text) {
    // Simplified Dart implementation for fallback
    // The full implementation would be in the existing keyboard logic
    return text;
  }
  
  static String _processEnglishTextDart(String text) {
    // English text processing fallback
    return text;
  }
  
  static String _processConjunctDart(String baseChar, String consonant, String language) {
    // Dart fallback for conjunct processing
    if (language == 'en' || baseChar.isEmpty || consonant.isEmpty) {
      return consonant;
    }
    
    // Simple conjunct formation (halant + consonant)
    const halant = '\u094D';
    if (_isDevanagariConsonant(baseChar) && _isDevanagariConsonant(consonant)) {
      return baseChar + halant + consonant;
    }
    
    return consonant;
  }
  
  static int _calculateDeleteCountDart(String textBeforeCursor) {
    if (textBeforeCursor.isEmpty) return 0;
    
    // Simple fallback - just delete one character
    // The native implementation handles conjuncts properly
    return 1;
  }
  
  static bool _isDevanagariConsonant(String char) {
    if (char.isEmpty) return false;
    final code = char.runes.first;
    return code >= 0x0915 && code <= 0x0939; // क to ह
  }
}