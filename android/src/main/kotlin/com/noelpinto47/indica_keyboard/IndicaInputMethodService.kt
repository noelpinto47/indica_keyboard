package com.noelpinto47.indica_keyboard

import android.content.Context
import android.inputmethodservice.InputMethodService
import android.text.InputType
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

/**
 * Native Android Input Method Service for Indica Keyboard
 * Provides high-performance text input with Flutter UI integration
 */
class IndicaInputMethodService : InputMethodService() {
    
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private var methodChannel: MethodChannel? = null
    private var currentLanguage = "en"
    private val mainHandler = Handler(Looper.getMainLooper())
    
    // Performance optimization: Cache for conjunct processing
    private val conjunctCache = ConcurrentHashMap<String, String>()
    
    // Native text processing for optimal performance
    private val textProcessor = IndicaTextProcessor()
    
    companion object {
        private const val CHANNEL = "com.noelpinto47.indica_keyboard/native"
        private const val METHOD_ON_KEY_PRESSED = "onKeyPressed"
        private const val METHOD_ON_LANGUAGE_CHANGED = "onLanguageChanged"
        private const val METHOD_GET_CURRENT_TEXT = "getCurrentText"
        private const val METHOD_PROCESS_CONJUNCT = "processConjunct"
    }
    
    override fun onCreateInputView(): View {
        // Initialize Flutter engine for native performance
        initializeFlutterEngine()
        
        // Create Flutter view for keyboard UI
        flutterView = FlutterView(this)
        flutterEngine?.let { engine ->
            flutterView?.attachToFlutterEngine(engine)
        }
        
        return flutterView ?: super.onCreateInputView()
    }
    
    private fun initializeFlutterEngine() {
        if (flutterEngine == null) {
            flutterEngine = FlutterEngine(this).apply {
                // Start Dart execution
                dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
            }
            
            // Set up method channel for native-Flutter communication
            setupMethodChannel()
        }
    }
    
    private fun setupMethodChannel() {
        flutterEngine?.let { engine ->
            methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).apply {
                setMethodCallHandler { call, result ->
                    handleMethodCall(call.method, call.arguments, result)
                }
            }
        }
    }
    
    private fun handleMethodCall(method: String, arguments: Any?, result: MethodChannel.Result) {
        when (method) {
            "insertText" -> {
                val text = arguments as? String ?: ""
                insertTextNative(text)
                result.success(true)
            }
            "deleteBackward" -> {
                deleteBackwardNative()
                result.success(true)
            }
            "switchLanguage" -> {
                val language = arguments as? String ?: "en"
                switchLanguageNative(language)
                result.success(true)
            }
            "processConjunct" -> {
                val input = arguments as? Map<String, String>
                val baseChar = input?.get("base") ?: ""
                val consonant = input?.get("consonant") ?: ""
                val conjunct = textProcessor.processConjunct(baseChar, consonant, currentLanguage)
                result.success(conjunct)
            }
            "getCurrentText" -> {
                val currentText = getCurrentInputText()
                result.success(currentText)
            }
            "shouldAutoCapitalize" -> {
                val shouldCap = shouldAutoCapitalize()
                result.success(shouldCap)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * High-performance native text insertion
     * Optimized for conjunct formation and auto-capitalization
     */
    private fun insertTextNative(text: String) {
        val ic = currentInputConnection ?: return
        
        try {
            // Process text based on current language
            val processedText = when (currentLanguage) {
                "hi", "mr" -> textProcessor.processDevanagariText(text, currentLanguage)
                "en" -> textProcessor.processEnglishText(text)
                else -> text
            }
            
            // Commit text with optimized batch editing
            ic.beginBatchEdit()
            ic.commitText(processedText, 1)
            ic.endBatchEdit()
            
            // Notify Flutter layer
            notifyFlutterTextChanged(processedText)
            
        } catch (e: Exception) {
            // Fallback to simple insertion
            ic.commitText(text, 1)
        }
    }
    
    /**
     * Native backspace handling with conjunct awareness
     */
    private fun deleteBackwardNative() {
        val ic = currentInputConnection ?: return
        
        try {
            if (currentLanguage in listOf("hi", "mr")) {
                // Smart deletion for Devanagari conjuncts
                val beforeCursor = ic.getTextBeforeCursor(3, 0)?.toString() ?: ""
                val deleteCount = textProcessor.calculateDeleteCount(beforeCursor)
                ic.deleteSurroundingText(deleteCount, 0)
            } else {
                // Standard deletion for English
                ic.deleteSurroundingText(1, 0)
            }
            
            // Notify Flutter layer
            notifyFlutterTextChanged("")
            
        } catch (e: Exception) {
            // Fallback deletion
            ic.deleteSurroundingText(1, 0)
        }
    }
    
    /**
     * Native language switching with optimized caching
     */
    private fun switchLanguageNative(language: String) {
        if (currentLanguage != language) {
            currentLanguage = language
            
            // Clear language-specific caches
            conjunctCache.clear()
            
            // Notify Flutter layer
            methodChannel?.invokeMethod(METHOD_ON_LANGUAGE_CHANGED, language)
        }
    }
    
    /**
     * Get current input text for auto-capitalization
     */
    private fun getCurrentInputText(): String {
        val ic = currentInputConnection ?: return ""
        return try {
            ic.getTextBeforeCursor(1000, 0)?.toString() ?: ""
        } catch (e: Exception) {
            ""
        }
    }
    
    /**
     * Native auto-capitalization logic for optimal performance
     */
    private fun shouldAutoCapitalize(): Boolean {
        if (currentLanguage != "en") return false
        
        val currentText = getCurrentInputText()
        if (currentText.isEmpty()) return true
        
        // Check for sentence endings
        val trimmed = currentText.trimEnd()
        if (trimmed.isEmpty()) return true
        
        val lastChar = trimmed.last()
        return lastChar in listOf('.', '!', '?')
    }
    
    /**
     * Notify Flutter layer of text changes
     */
    private fun notifyFlutterTextChanged(text: String) {
        mainHandler.post {
            methodChannel?.invokeMethod("onTextChanged", text)
        }
    }
    
    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        
        // Initialize for new input session
        conjunctCache.clear()
        
        // Determine initial language based on input type
        val initialLanguage = when (attribute?.inputType?.and(InputType.TYPE_MASK_CLASS)) {
            InputType.TYPE_CLASS_TEXT -> {
                // Check for specific locales or use default
                "en"
            }
            else -> "en"
        }
        
        switchLanguageNative(initialLanguage)
    }
    
    override fun onFinishInput() {
        super.onFinishInput()
        
        // Clean up caches for memory efficiency
        conjunctCache.clear()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // Clean up Flutter resources
        flutterView?.detachFromFlutterEngine()
        flutterEngine?.destroy()
        flutterEngine = null
        flutterView = null
        methodChannel = null
    }
    
    // Hardware key support for better compatibility
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_BACK -> {
                // Handle back key if needed
                super.onKeyDown(keyCode, event)
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }
}