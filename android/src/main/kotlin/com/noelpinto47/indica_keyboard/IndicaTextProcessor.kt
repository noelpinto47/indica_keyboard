package com.noelpinto47.indica_keyboard

import java.util.concurrent.ConcurrentHashMap

/**
 * High-performance native text processor for Indica Keyboard
 * Optimized for Devanagari conjunct formation and English auto-capitalization
 */
class IndicaTextProcessor {
    
    // Performance caches for repeated operations
    private val conjunctCache = ConcurrentHashMap<String, String>()
    private val devanagariCache = ConcurrentHashMap<String, Boolean>()
    
    companion object {
        // Devanagari Unicode ranges for efficient checking
        private const val DEVANAGARI_START = 0x0900
        private const val DEVANAGARI_END = 0x097F
        private const val HALANT = '\u094D'
        
        // Common conjunct mappings for fast lookup
        private val CONJUNCT_MAP = mapOf(
            // Hindi common conjuncts
            "क्त" to "क्त",
            "क्य" to "क्य", 
            "न्न" to "न्न",
            "त्त" to "त्त",
            "द्द" to "द्द",
            "प्त" to "प्त",
            "स्त" to "स्त",
            "श्र" to "श्र",
            
            // Marathi specific conjuncts
            "ज्ञ" to "ज्ञ",
            "त्र" to "त्र",
            "क्ष" to "क्ष"
        )
        
        // Sentence ending characters for auto-capitalization
        private val SENTENCE_ENDINGS = setOf('.', '!', '?')
    }
    
    /**
     * Process English text with auto-capitalization
     * Optimized for minimal latency
     */
    fun processEnglishText(input: String): String {
        if (input.length != 1) return input
        
        val char = input[0]
        
        // Only process alphabetic characters
        if (!char.isLetter()) return input
        
        // Auto-capitalization logic would be handled by Flutter layer
        // This method focuses on native text processing
        return input
    }
    
    /**
     * Process Devanagari text with conjunct formation
     * High-performance implementation with caching
     */
    fun processDevanagariText(input: String, language: String): String {
        if (input.isEmpty()) return input
        
        // Use cache for repeated inputs
        val cacheKey = "$input-$language"
        conjunctCache[cacheKey]?.let { return it }
        
        val result = when {
            input.length == 1 && isDevanagariConsonant(input[0]) -> {
                // Single consonant - prepare for potential conjunct
                input
            }
            input.length > 1 -> {
                // Multi-character input - process for conjuncts
                processConjunctSequence(input, language)
            }
            else -> input
        }
        
        // Cache result for performance
        conjunctCache[cacheKey] = result
        return result
    }
    
    /**
     * Process conjunct formation between two characters
     * Optimized with pre-computed mappings
     */
    fun processConjunct(baseChar: String, consonant: String, language: String): String {
        if (baseChar.isEmpty() || consonant.isEmpty()) return consonant
        
        // Quick lookup for common conjuncts
        val combination = baseChar + consonant
        CONJUNCT_MAP[combination]?.let { return it }
        
        // Generate conjunct if both are Devanagari consonants
        if (baseChar.length == 1 && consonant.length == 1 &&
            isDevanagariConsonant(baseChar[0]) && isDevanagariConsonant(consonant[0])) {
            
            // Form conjunct: base consonant + halant + joining consonant
            return baseChar + HALANT + consonant
        }
        
        return consonant
    }
    
    /**
     * Calculate smart deletion count for Devanagari text
     * Handles conjuncts as single units
     */
    fun calculateDeleteCount(textBeforeCursor: String): Int {
        if (textBeforeCursor.isEmpty()) return 0
        
        // Check if last character is part of a conjunct
        var count = 1
        val len = textBeforeCursor.length
        
        if (len >= 2 && textBeforeCursor[len - 1].let { isDevanagariConsonant(it) || isDevanagariVowel(it) }) {
            // Check for halant before the last character (conjunct pattern)
            if (len >= 3 && textBeforeCursor[len - 2] == HALANT) {
                // This is likely a conjunct - delete the whole sequence
                count = 2
                
                // Check for longer conjunct sequences
                var pos = len - 3
                while (pos >= 0 && isDevanagariConsonant(textBeforeCursor[pos])) {
                    if (pos > 0 && textBeforeCursor[pos - 1] == HALANT) {
                        count += 2
                        pos -= 2
                    } else {
                        break
                    }
                }
            }
        }
        
        return count
    }
    
    /**
     * Process sequence of characters for conjunct formation
     */
    private fun processConjunctSequence(input: String, language: String): String {
        if (input.length < 2) return input
        
        val result = StringBuilder()
        var i = 0
        
        while (i < input.length) {
            val currentChar = input[i]
            
            if (i < input.length - 1 && isDevanagariConsonant(currentChar)) {
                val nextChar = input[i + 1]
                if (isDevanagariConsonant(nextChar)) {
                    // Potential conjunct
                    val conjunct = processConjunct(currentChar.toString(), nextChar.toString(), language)
                    result.append(conjunct)
                    i += 2 // Skip both characters
                    continue
                }
            }
            
            result.append(currentChar)
            i++
        }
        
        return result.toString()
    }
    
    /**
     * Optimized Devanagari consonant detection with caching
     */
    private fun isDevanagariConsonant(char: Char): Boolean {
        val cacheKey = char.toString()
        devanagariCache[cacheKey]?.let { return it }
        
        val result = char.code in 0x0915..0x0939 // क to ह
        devanagariCache[cacheKey] = result
        return result
    }
    
    /**
     * Check if character is Devanagari vowel
     */
    private fun isDevanagariVowel(char: Char): Boolean {
        return char.code in 0x0905..0x0914 || // Independent vowels अ to औ
               char.code in 0x093E..0x094C || // Dependent vowels ा to ौ
               char.code == 0x0902 || char.code == 0x0903 // Anusvara and Visarga
    }
    
    /**
     * Check if character is in Devanagari range
     */
    private fun isDevanagari(char: Char): Boolean {
        return char.code in DEVANAGARI_START..DEVANAGARI_END
    }
    
    /**
     * Clear all caches for memory management
     */
    fun clearCaches() {
        conjunctCache.clear()
        devanagariCache.clear()
    }
    
    /**
     * Get cache statistics for debugging
     */
    fun getCacheStats(): Map<String, Int> {
        return mapOf(
            "conjunctCacheSize" to conjunctCache.size,
            "devanagariCacheSize" to devanagariCache.size
        )
    }
    
    /**
     * Main text processing method
     */
    fun processText(text: String, language: String): String {
        return when (language) {
            "hi", "mr" -> processDevanagariText(text, language)
            "en" -> processEnglishText(text)
            else -> text
        }
    }
    
    /**
     * Process multiple texts in batch for better performance
     */
    fun processBatchText(texts: List<String>, language: String): List<String> {
        return texts.map { text -> processText(text, language) }
    }
}