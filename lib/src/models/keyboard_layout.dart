/// Keyboard layout models and configurations for multilingual support
class KeyboardLayout {
  /// List of supported language codes
  static const List<String> supportedLanguages = ['en', 'hi', 'mr'];
  
  /// Performance cache for layouts
  static final Map<String, List<List<String>>> _layoutCache = {};
  static List<List<String>>? _cachedNumericLayout;

  /// Get keyboard layout for a specific language and page
  static List<List<String>> getLayoutForLanguage(String lang, {int page = 0, String? selectedLetter}) {
    // Performance optimization: Use cached layouts for static pages
    final cacheKey = '${lang}_${page}_${selectedLetter ?? 'null'}';
    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey]!;
    }

    List<List<String>> layout;
    switch (lang) {
      case 'en':
        layout = [
          ['1','2','3','4','5','6','7','8','9','0'],
          ['q','w','e','r','t','y','u','i','o','p'],
          ['a','s','d','f','g','h','j','k','l'],
          ['z','x','c','v','b','n','m']
        ];
        break;
      case 'hi': // Hindi (Devanagari) - Multiple pages
        layout = _getHindiLayoutPage(page, selectedLetter: selectedLetter);
        break;
      case 'mr': // Marathi (Devanagari) - Multiple pages  
        layout = _getMarathiLayoutPage(page, selectedLetter: selectedLetter);
        break;
      default:
        layout = [];
    }
    
    // Cache the layout for future use (only cache static layouts)
    if (selectedLetter == null && layout.isNotEmpty) {
      _layoutCache[cacheKey] = layout;
    }
    
    return layout;
  }

  /// Get Hindi keyboard layout for specific page
  static List<List<String>> _getHindiLayoutPage(int page, {String? selectedLetter}) {
    switch (page) {
      case 0: // Page 1/4 - Dynamic top row + consonants
        return [
          [
            '\u093E','\u093F','\u0940',
            '\u0941','\u0942','\u0947',
            '\u0948','\u094B','\u094C',
            '\u0902','\u0903',
          ],
          ['क','ख','ग','घ','ड़','च','छ','ज','झ','\u093C','\u0901'],
          ['ट','ठ','ड','ढ','ण','त','थ','द','ध','न', 'ञ'],
          ['प','फ','ब','भ','म','य','र','ल','व','श', 'ष'],
          ['स','ह','क्ष','त्र','ज्ञ','श्र','ऋ','\u0943','्']
        ];
      case 1: // Page 2/4 - Conjunct consonants
        return [
           ['अ','आ','इ','ई','उ','ऊ','ए','ऐ','ओ','औ'],
          ['ध्र','प्र','ब्र','भ्र','म्र','फ्र','व्र','ह्म', 'अं', 'अः'],
          ['र्र', 'स्व', 'ह', 'र्क', 'र्ग', 'र्च', 'र्ज', 'र्त', 'र्थ', 'र्द'],
          ['र्न', 'र्म', 'र्श', 'र्ष', 'र्स', 'र्प', 'त्थ', 'त्स', 'त', 'त्य'],
          ['त्व', 'द्द', 'द्ध', 'द्ब', 'द्भ', 'द्य', 'द्र', 'द्व']
        ];
      case 2: // Page 3/4 - Advanced conjunct consonants
        return [
          ['न्न', 'न्म', 'न्य', 'न्त', 'न्द', 'न्ध', 'न्स', 'प्त', 'प्न', 'प्प'],
          ['प्म', 'प्य', 'प्र', 'प्ल', 'प्व', 'प्स', 'फ्र', 'ब्ज', 'ब्द', 'ब्ध'],
          ['ब्न', 'ब्ब', 'ब्म', 'ब्य', 'ब्र', 'ब्ल', 'ब्व', 'भ्य', 'भ्र', 'भ्व'],
          ['म्न', 'म्प', 'म्फ', 'म्ब', 'म्भ', 'म्म', 'म्य', 'म्र', 'म्ल', 'म्व'],
          ['य्य', 'र्क', 'र्ख', 'र्ग', 'र्घ', 'र्च', 'र्छ', 'र्ज', 'र्झ', 'र्ञ']
        ];
      case 3: // Page 4/4 - Numbers and symbols
        return [
          ['०','१','२','३','४','५','६','७','८','९'],
          ['।','॥','ॐ','ऽ','॰','ॱ','ॲ','ॳ','ॴ','ॵ'],
          ['ॶ','ॷ','ॸ','ॹ','ॺ','ॻ','ॼ','ॽ','ॾ','ॿ'],
          ['₹', '।', '॥', 'ॐ', '्', 'ऽ', '॒', '॓', '॔', '॰'],
          ['क़', 'ख़', 'ग़', 'ज़', 'ड़', 'ढ़', 'फ़', 'य़', '।', '॥']
        ];
      default:
        return [];
    }
  }

  /// Get Marathi keyboard layout for specific page  
  static List<List<String>> _getMarathiLayoutPage(int page, {String? selectedLetter}) {
    switch (page) {
      case 0: // Page 1/4 - Basic Marathi layout with dynamic top row
        return [
          [
            '\u093E','\u093F','\u0940',
            '\u0941','\u0942','\u0947',
            '\u0948','\u094B','\u094C',
            '\u0902','\u0903',
          ],
          ['क','ख','ग','घ','ड़','च','छ','ज','झ','\u093C','\u0901'],
          ['ट','ठ','ड','ढ','ण','त','थ','द','ध','न','ञ'],
          ['प','फ','ब','भ','म','य','र','ल','ळ','व','श'],
          ['स','ह','ळ्ह','क्ष','ज्ञ','त्र','ऋ','\u0943','्']
        ];
      case 1: // Page 2/4 - Marathi conjunct consonants
        return [
           ['अ','आ','इ','ई','उ','ऊ','ए','ऐ','ओ','औ'],
          ['ध्र','प्र','ब्र','भ्र','म्र','फ्र','व्र','ह्म','अं', 'अः'],
          ['र्र','स्व','ह','र्क','र्ग','र्च','र्ज','र्त','र्थ','र्द'],
          ['र्न','र्म','र्श','र्ष','र्स','र्प','त्थ','त्स','ळ्ह','त्य'],
          ['त्व','द्द','द्ध','द्ब','द्भ','द्य','द्र','द्व']
        ];
      case 2: // Page 3/4 - Advanced Marathi conjuncts
        return [
          ['ट्','ख्','य्','श्च','ज्य','त्य','ध्य','प्य','भ्र','ल्य'],
          ['व्य','प्य','स्य','न्त','न्द','न्थ','न्ह','ळ्य','न्य','ळ्प'],
          ['म्च','स्त','स्न','स्प','स्ब','म्म','म्य','म्ह','ळ्ट','ळ्ठ'],
          ['ष्ट','ष्ठ','ष्ण','प्ल','ब्ज','ब्द','ब्ब','ब्ल','श्च','श्व'],
          ['ल्ट','ल्प','ल्ब','ल्ह','ळ्ल','ष्प','ष्क','ळ्म']
        ];
      case 3: // Page 4/4 - Special Marathi vowels and symbols
        return [
          ['ऍ','ऑ','ऐ','ओ','औ','अं','अः','अ','आ','ऋ'],
          ['ॅ','ॉ','ै','ो','ौ','ं','ः','ॲ','ऻ','ॄ'],
          ['ल्','ल्ल','ळ्','ळ्ळ','क्ष','ज्ञ','त्र','श्र','द्ध','ब'],
          ['ऴ','ऴ','ळ','ळ','ॅ','ॉ','?','न','र','ळ्य'],
          ['०','\\\\','\'','।','॰','\$','॥','ॐ']
        ];
      default:
        return _getMarathiLayoutPage(0, selectedLetter: selectedLetter);
    }
  }

  static List<List<String>> getNumericLayout() {
    // Performance: Cache numeric layout since it never changes
    _cachedNumericLayout ??= [
      ['1','2','3','4','5','6','7','8','9','0'],
      ['@','#','\$','_','&','-','+','(',')','/',],
      ['*','"','\'',':',';','!','?','~','<','>'],
      ['more','=','{','}','[',']','\\','%','^'],
    ];
    return _cachedNumericLayout!;
  }

  /// Check if a character is a consonant that can take vowel attachments
  static bool isConsonant(String char, String language) {
    if (language == 'hi' || language == 'mr') {
      // List of common Devanagari consonants (including nukta variations)
      const consonants = [
        'क','ख','ग','घ','ङ','च','छ','ज','झ','ञ',
        'ट','ठ','ड','ढ','ण','त','थ','द','ध','न',
        'प','फ','ब','भ','म','य','र','ल','व','श',
        'ष','स','ह','क़','ख़','ग़','ज़','ड़','ढ़','फ़','य़'
      ];
      return consonants.contains(char);
    }
    return false;
  }

  /// Get language name for display
  static String getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'hi': return 'हिंदी (Hindi)';
      case 'mr': return 'मराठी (Marathi)';
      default: return code.toUpperCase();
    }
  }

  /// Get maximum pages for a language
  static int getMaxLayoutPages(String language) {
    switch (language) {
      case 'hi': return 4;
      case 'mr': return 4;
      default: return 1;
    }
  }

  /// Performance optimization: Pre-warm all layout caches
  static void preWarmAllCaches() {
    // Pre-load all layouts for all languages and pages
    for (final lang in supportedLanguages) {
      if (lang == 'en') {
        getLayoutForLanguage(lang);
      } else {
        // Load all pages for non-English languages
        final maxPages = getMaxLayoutPages(lang);
        for (int page = 0; page < maxPages; page++) {
          getLayoutForLanguage(lang, page: page);
        }
      }
    }
    
    // Pre-load numeric layout
    getNumericLayout();
  }
}