/// 🚀 Performance constants and optimizations for keyboard
class PerformanceConstants {
  // Cache sizes for optimal memory usage
  static const int maxLayoutCache = 20;
  static const int maxTextStyleCache = 15;
  static const int maxDecorationCache = 10;
  
  // Timing constants for debouncing and throttling
  static const Duration textChangeDebounce = Duration(milliseconds: 16); // 60fps
  static const Duration heightRecalculation = Duration(milliseconds: 100);
  static const Duration layoutCacheExpiry = Duration(seconds: 30);
  
  // Performance thresholds
  static const double minKeyHeight = 25.0;
  static const double maxKeyHeight = 60.0;
  static const int maxRepaintBoundaryDepth = 3;
  
  // Native performance hints
  static const bool enableNativeOptimizations = true;
  static const bool useHardwareAcceleration = true;
  static const bool enableRepaintBoundaries = true;
  
  // Memory management
  static const int gcThresholdKeyPresses = 1000;
  static const Duration memoryCleanupInterval = Duration(minutes: 5);
}

/// 🚀 Performance utilities for keyboard optimization
class PerformanceUtils {
  static const Map<String, dynamic> _cache = {};
  static int _keyPressCount = 0;
  
  /// Get cached value or compute and cache it
  static T getCached<T>(String key, T Function() computeFunction) {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }
    
    final value = computeFunction();
    _cache[key] = value;
    return value;
  }
  
  /// Clear cache when memory pressure detected
  static void clearCache() {
    _cache.clear();
  }
  
  /// Increment key press counter and trigger GC if needed
  static void onKeyPress() {
    _keyPressCount++;
    if (_keyPressCount % PerformanceConstants.gcThresholdKeyPresses == 0) {
      // Trigger garbage collection hint for native platforms
      clearCache();
    }
  }
  
  /// Check if repaint boundary should be used
  static bool shouldUseRepaintBoundary(int depth) {
    return PerformanceConstants.enableRepaintBoundaries && 
           depth <= PerformanceConstants.maxRepaintBoundaryDepth;
  }
}