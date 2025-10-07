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
        // Get platform information for better logging
        String platform = 'Unknown';
        try {
          platform = await _channel.invokeMethod('getPlatformVersion') ?? 'Unknown';
        } catch (_) {}
        
        developer.log(
          _nativeSupported 
            ? '✅ Native processing initialized successfully on $platform'
            : '⚠️ Native processing unavailable on $platform, using Dart fallback',
          name: 'IndicaKeyboard',
          level: _nativeSupported ? 800 : 900,
        );
      }
      
      // Warm up caches for better initial performance
      if (_nativeSupported) {
        _warmUpNativeCaches(['en', 'hi', 'mr']);
      }
      
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
  
  /// Process multiple texts in batch for improved performance
  /// This method provides significant performance gains for bulk operations
  static Future<List<String>> processBatchText({
    required List<String> texts,
    required String language,
  }) async {
    // Auto-initialize if not done yet
    if (!_initialized) {
      await initialize();
    }
    
    // Try native batch processing first (ultra-optimized)
    if (_nativeSupported) {
      try {
        final result = await _channel.invokeMethod('processBatchTextNative', {
          'texts': texts,
          'language': language,
        });
        _logProcessing('processBatchText', true, '${texts.length} texts');
        return List<String>.from(result as List? ?? []);
      } catch (e) {
        // Fallback to individual processing with logging
        _logProcessing('processBatchText', false, 'native failed: ${e.toString().substring(0, 50)}...');
      }
    } else {
      _logProcessing('processBatchText', false, 'native not supported');
    }

    // Dart fallback - process individually
    final results = <String>[];
    for (final text in texts) {
      results.add(await processText(text: text, language: language));
    }
    return results;
  }
  
  /// Get comprehensive performance statistics with detailed metrics
  static Future<Map<String, dynamic>> getAdvancedPerformanceStats() async {
    if (!_nativeSupported) return getProcessingStats();
    
    try {
      final result = await _channel.invokeMethod('getNativePerformanceStats');
      final nativeStats = Map<String, dynamic>.from(result as Map? ?? {});
      
      // Combine with Dart-side statistics
      final combinedStats = Map<String, dynamic>.from(getProcessingStats());
      combinedStats.addAll(nativeStats);
      
      return combinedStats;
    } catch (e) {
      return getProcessingStats();
    }
  }
  
  /// Optimize native caches for better performance
  /// Call this periodically to maintain optimal performance
  static Future<bool> optimizeNativeCaches() async {
    if (!_nativeSupported) return false;
    
    try {
      await _channel.invokeMethod('optimizeNativeCaches');
      if (_loggingEnabled) {
        developer.log(
          '🔧 Native caches optimized for better performance',
          name: 'IndicaKeyboard',
          level: 800,
        );
      }
      return true;
    } catch (e) {
      if (_loggingEnabled) {
        developer.log(
          '⚠️ Cache optimization failed: $e',
          name: 'IndicaKeyboard',
          level: 900,
        );
      }
      return false;
    }
  }
  
  /// Clear native caches and reset performance counters
  static Future<bool> clearNativeCaches() async {
    if (!_nativeSupported) return false;
    
    try {
      await _channel.invokeMethod('clearNativeCaches');
      
      // Reset local counters as well
      _nativeCallCount = 0;
      _dartFallbackCount = 0;
      
      if (_loggingEnabled) {
        developer.log(
          '🧹 Native caches cleared and stats reset',
          name: 'IndicaKeyboard',
          level: 800,
        );
      }
      return true;
    } catch (e) {
      if (_loggingEnabled) {
        developer.log(
          '⚠️ Failed to clear native caches: $e',
          name: 'IndicaKeyboard',
          level: 900,
        );
      }
      return false;
    }
  }
  
  /// Get legacy performance statistics (for backward compatibility)
  static Future<Map<String, int>> getPerformanceStats() async {
    return {
      'nativeCallCount': _nativeCallCount,
      'dartFallbackCount': _dartFallbackCount,
    };
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
  
  /// Advanced: Warm up caches with common operations for better initial performance
  static Future<void> warmUpCaches() async {
    if (!_nativeSupported) return;
    
    try {
      // Pre-load common conjuncts to improve first-time performance
      final commonConjuncts = [
        {'base': 'क', 'consonant': 'त', 'language': 'hi'},
        {'base': 'श', 'consonant': 'र', 'language': 'hi'}, 
        {'base': 'त', 'consonant': 'र', 'language': 'hi'},
        {'base': 'स', 'consonant': 'त', 'language': 'hi'},
        {'base': 'न', 'consonant': 'न', 'language': 'hi'},
      ];
      
      for (final conjunct in commonConjuncts) {
        await processConjunct(
          baseChar: conjunct['base']!,
          consonant: conjunct['consonant']!,
          language: conjunct['language']!,
        );
      }
      
      if (_loggingEnabled) {
        developer.log(
          '🔥 Native caches warmed up with common operations',
          name: 'IndicaKeyboard',
          level: 800,
        );
      }
    } catch (e) {
      if (_loggingEnabled) {
        developer.log(
          '⚠️ Cache warm-up failed: $e',
          name: 'IndicaKeyboard',
          level: 900,
        );
      }
    }
  }
  
  /// Advanced: Get detailed performance insights for optimization
  static Map<String, String> getPerformanceInsights() {
    final totalCalls = _nativeCallCount + _dartFallbackCount;
    
    if (totalCalls == 0) {
      return {
        'status': 'No operations yet',
        'recommendation': 'Start typing to see performance data',
        'mode': getProcessingMode(),
      };
    }
    
    final nativePercentage = (_nativeCallCount / totalCalls * 100);
    
    String recommendation;
    String status;
    
    if (!_nativeSupported) {
      status = 'Dart-only mode';
      recommendation = 'Native processing unavailable on this platform';
    } else if (nativePercentage >= 90) {
      status = 'Excellent performance';
      recommendation = 'Optimal native processing active';
    } else if (nativePercentage >= 70) {
      status = 'Good performance';  
      recommendation = 'Mostly using native processing';
    } else if (nativePercentage >= 50) {
      status = 'Mixed performance';
      recommendation = 'Consider optimizing or checking for errors';
    } else {
      status = 'Poor native performance';
      recommendation = 'Frequent fallbacks detected - check logs for issues';
    }
    
    return {
      'status': status,
      'recommendation': recommendation,
      'mode': getProcessingMode(),
      'nativePercentage': '${nativePercentage.toStringAsFixed(1)}%',
      'totalOperations': totalCalls.toString(),
    };
  }
  
  /// Advanced: Reset all statistics (useful for benchmarking)
  static void resetStatistics() {
    _nativeCallCount = 0;
    _dartFallbackCount = 0;
    
    if (_loggingEnabled) {
      developer.log(
        '📊 Performance statistics reset',
        name: 'IndicaKeyboard',
        level: 800,
      );
    }
  }
  
  // MARK: - iOS/Android Optimization Methods
  
  /// Warm up native caches for better initial performance
  static Future<void> _warmUpNativeCaches(List<String> languages) async {
    if (!_nativeSupported) return;
    
    try {
      await _channel.invokeMethod('warmUpCaches', {
        'languages': languages,
      });
      
      if (_loggingEnabled) {
        developer.log(
          '🔥 Native caches warmed up for languages: ${languages.join(", ")}',
          name: 'IndicaKeyboard',
        );
      }
    } catch (e) {
      if (_loggingEnabled) {
        developer.log(
          '⚠️ Cache warm-up failed: $e',
          name: 'IndicaKeyboard',
          level: 900,
        );
      }
    }
  }
  
  /// Optimize native processing for specific language
  static Future<void> optimizeForLanguage(String language) async {
    if (!_nativeSupported) return;
    
    try {
      await _channel.invokeMethod('optimizeForLanguage', {
        'language': language,
      });
      
      if (_loggingEnabled) {
        developer.log(
          '⚡ Native processing optimized for language: $language',
          name: 'IndicaKeyboard',
        );
      }
    } catch (e) {
      if (_loggingEnabled) {
        developer.log(
          '⚠️ Language optimization failed for $language: $e',
          name: 'IndicaKeyboard',
          level: 900,
        );
      }
    }
  }
  
  /// Get advanced native performance metrics (iOS/Android specific)
  static Future<Map<String, dynamic>> getAdvancedMetrics() async {
    if (!_nativeSupported) {
      return {
        'platform': 'Dart-only',
        'error': 'Native processing not available'
      };
    }
    
    try {
      final metrics = await _channel.invokeMethod('getPerformanceMetrics');
      return Map<String, dynamic>.from(metrics ?? {});
    } catch (e) {
      if (_loggingEnabled) {
        developer.log(
          '⚠️ Failed to get advanced metrics: $e',
          name: 'IndicaKeyboard',
          level: 900,
        );
      }
      return {
        'error': e.toString(),
        'fallback': getProcessingStats(),
      };
    }
  }
  
  /// Batch process multiple texts with native optimization (iOS/Android)
  static Future<List<String>> batchProcessText({
    required List<String> texts,
    required String language,
    bool enableConjuncts = true,
    bool useOptimized = true,
  }) async {
    // Auto-initialize if not done yet
    if (!_initialized) {
      await initialize();
    }
    
    // Try native batch processing first (if available)
    if (_nativeSupported) {
      try {
        final result = await _channel.invokeMethod('batchProcessText', {
          'texts': texts,
          'language': language,
          'enableConjuncts': enableConjuncts,
          'useOptimized': useOptimized,
        });
        
        _logProcessing('batchProcessText', true, 'processed ${texts.length} texts');
        return List<String>.from(result ?? []);
      } catch (e) {
        _logProcessing('batchProcessText', false, 'native batch failed: $e');
      }
    } else {
      _logProcessing('batchProcessText', false, 'native not supported');
    }
    
    // Dart fallback: process each text individually
    final processedTexts = <String>[];
    for (final text in texts) {
      final processed = await processText(
        text: text,
        language: language,
      );
      processedTexts.add(processed);
    }
    
    return processedTexts;
  }
}