## 1.1.1 - Critical Conjunct Mode Fix

* **🔧 FIXED: Conjunct Mode Deactivation** - Resolved issue where conjunct formation button (+) in Hindi/Marathi keyboards would activate but not visually deactivate
* **🎯 ENHANCED: ValueNotifier Consistency** - Fixed missing ValueNotifier update in async conjunct processing method for immediate UI feedback
* **🛡️ IMPROVED: Error Handling** - Added proper early return when conjunct formation fails to prevent state confusion
* **🔄 ENHANCED: Language Switching** - Conjunct mode now properly resets when switching between languages for clean state management
* **✨ REFINED: Visual Feedback** - Conjunct button appearance now perfectly matches internal state in all scenarios

## 1.1.0 - Performance Revolution & Auto-Capitalization Excellence

* **🚀 MAJOR: Performance Architecture Overhaul** - Revolutionary ValueNotifier system for granular UI updates, eliminating unnecessary full widget rebuilds
* **⚡ PERFORMANCE: Smart Keyboard Height System** - Dynamic height calculation using system keyboard proportions with 40% landscape limit and expandable key architecture
* **🔤 FIXED: Auto-Capitalization Visual State** - Complete resolution of auto-capitalization display issues - keyboard now perfectly reflects capitalization state for all sentences
* **🎯 ENHANCED: Hindi Layout Page Switching** - Fixed 1/4 → 2/4 page navigation with proper ValueNotifier integration
* **💾 OPTIMIZED: Intelligent Caching System** - Advanced performance caching with proper cache invalidation for consistent UI updates
* **🔧 PERFORMANCE: RepaintBoundary Optimization** - Strategic repaint boundaries and micro-batched updates for 60fps rendering
* **📐 ENHANCED: Expandable Key System** - Keys dynamically resize to optimally fill available keyboard height with density-aware calculations
* **🎨 IMPROVED: Visual Consistency** - Eliminated cache-related stale UI states with direct method calls for display logic
* **🛡️ RELIABILITY: setState Strategy** - Hybrid approach using ValueNotifiers for granular updates and setState for full keyboard changes

## 1.0.1 - Enhanced Control & User Experience

* **🔧 NEW: currentLanguage Parameter** - Added optional `currentLanguage` parameter for external language state synchronization
* **🔄 ENHANCED: Bidirectional Language Sync** - Perfect synchronization between app language state and keyboard display
* **🎯 IMPROVED: Developer Control** - Developers can now programmatically control keyboard language from parent widgets
* **📱 ENHANCED: didUpdateWidget Implementation** - Automatic keyboard updates when language changes externally
* **🛠️ IMPROVED: API Flexibility** - Backward compatible enhancement for better integration patterns
* **📚 ENHANCED: Example App** - Updated example demonstrating new currentLanguage parameter usage
* **✨ REFINED: User Experience** - Smoother language switching with improved state management

## 1.0.0 - Production Release

* **🎉 MILESTONE: Production Ready** - First stable release with comprehensive testing and optimization
* **🚀 MAJOR: Cross-Platform Excellence** - Full iOS and Android native integration with platform-optimized performance
* **🌐 MAJOR: Enhanced Multilingual Support** - Refined English, Hindi, and Marathi language support with improved text processing
* **⚡ MAJOR: Performance Optimization** - Up to 5x faster text processing with native implementations and intelligent caching
* **🛡️ MAJOR: Enterprise-Grade Reliability** - Robust error handling, automatic fallbacks, and production-tested stability
* **📱 NEW: iOS Native Integration** - Complete iOS platform support with Swift-based text processing optimization
* **🔧 NEW: Advanced Configuration** - Comprehensive customization options for themes, layouts, and behavior
* **📊 NEW: Production Metrics** - Built-in performance monitoring and analytics for production environments
* **🎯 ENHANCED: Developer Experience** - Simplified API, comprehensive documentation, and extensive examples
* **🔄 ENHANCED: Smart Fallback System** - Intelligent native-to-Dart fallback with zero configuration required
* **✨ ENHANCED: UI/UX Polish** - Refined visual design, smooth animations, and improved haptic feedback
* **🧠 OPTIMIZED: Memory Management** - Advanced caching strategies and memory optimization for sustained performance
* **📚 BREAKING: API Finalization** - Stable public API with backward compatibility guarantees

## 0.1.0 - Native Android Integration

* **🚀 MAJOR: Native Android Processing** - Ultra-optimized native text processing with 3-5x performance improvement
* **🧠 MAJOR: Smart Memory Management** - LRU caches and object pooling for 60% less memory usage
* **🔄 MAJOR: Automatic Fallback System** - Transparent native-to-Dart fallback with zero configuration
* **📊 NEW: Performance Monitoring** - Real-time performance metrics and comprehensive logging
* **⚡ NEW: Batch Processing** - Process multiple operations in single native call for 3x speed boost
* **🛡️ NEW: Production Ready** - Enterprise-grade optimization with automatic error handling
* **📱 ENHANCED: Android Platform Integration** - TextUtils, ArrayMap, and platform-optimized collections
* **🎯 ENHANCED: API Simplification** - Removed IndicaKeyboardField, focused on single IndicaKeyboard widget
* **🔧 ENHANCED: Developer Experience** - Advanced debugging, cache optimization, and performance insights
* **✨ BREAKING: Simplified Public API** - Only IndicaKeyboard widget exported for cleaner integration

## 0.0.2

* **NEW: Conjunct Consonant Formation** - Added '+' button functionality for creating conjunct consonants in Devanagari scripts (Hindi/Marathi)
* **NEW: IndicaKeyboardField Widget** - Complete keyboard input solution with integrated TextField and automatic focus management
* **IMPROVED: Focus Management** - Internal focus node handling eliminates need for manual focus setup
* **IMPROVED: Text Input Handling** - Cursor-aware text input and backspace functionality moved inside the package
* **IMPROVED: User Experience** - Toggle conjunct mode on/off with visual feedback and intuitive consonant ordering
* **ENHANCED: API Simplification** - Reduced integration code from 50+ lines to just 3 lines for basic usage
* **ENHANCED: Examples** - Added simple_example.dart showing ultra-simplified usage

## 0.0.1

* Initial release of Indica Keyboard Plugin
* Multi-language support for English, Hindi, and Marathi
* Smart text input with vowel attachments for Devanagari scripts
* Dynamic keyboard layouts with multiple pages for complex scripts
* Customizable UI with theming support  
* Haptic feedback integration
* Three-state shift functionality for English
* Context-sensitive keyboard behavior
* Comprehensive example app demonstrating all features
