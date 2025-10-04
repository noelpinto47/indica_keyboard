/// Keyboard layout models and configurations for multilingual support
class KeyboardLayout {
  /// List of supported language codes
  static const List<String> supportedLanguages = ['en', 'hi', 'mr'];

  /// Get keyboard layout for a specific language and page
  static List<List<String>> getLayoutForLanguage(String lang, {int page = 0, String? selectedLetter}) {
    switch (lang) {
      case 'en':
        return [
          ['1','2','3','4','5','6','7','8','9','0'],
          ['q','w','e','r','t','y','u','i','o','p'],
          ['a','s','d','f','g','h','j','k','l'],
          ['z','x','c','v','b','n','m']
        ];
      case 'hi': // Hindi (Devanagari) - Multiple pages
        return _getHindiLayoutPage(page, selectedLetter: selectedLetter);
      case 'mr': // Marathi (Devanagari) - Multiple pages  
        return _getMarathiLayoutPage(page, selectedLetter: selectedLetter);
      default:
        return [];
    }
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
          ['ज्ञ','त्र','स्त','स्त','ड्ड','ज्ज','श्र','क्र','ग्र','द्र'],
          ['ध्र','प्र','ब्र','भ्र','म्र','फ्र','व्र','त्क','त्त','ह्म'],
          ['र्र', 'स्व', 'ह', 'र्क', 'र्ग', 'र्च', 'र्ज', 'र्त', 'र्थ', 'र्द'],
          ['र्न', 'र्म', 'र्श', 'र्ष', 'र्स', 'र्प', 'त्थ', 'त्स', 'त', 'त्य'],
          ['त्व', 'द्द', 'द्ध', 'द्ब', 'द्भ', 'द्य', 'द्र', 'द्व']
        ];
      case 2: // Page 3/4 - Advanced conjunct consonants
        return [
          ['ट्','ख्','य्','रख्','ज्य','त्य','ध्य','प्य','भ्र','ल्य'],
          ['व्य','प्य','स्य','न्त','न्त','न्थ','न्द','त्र','न्य','न्ह'],
          ['म्च','स्त','स्न','स्प','स्ब','म्म','म्य','म्ह','एड','एत'],
          ['पा','प्ल','बज','बद','ब्ब','ब्ल','ध्न','प्त','श्र','श्व'],
          ['ल्ट','ल्प','ल्ब','ल्ह','ष','ष्ण','ष्प','ष्क']
        ];
      case 3: // Page 4/4 - Special vowels and symbols
        return [
          ['ऍ','ऑ','ऐ','ओ','औ','अं','अः','अ','आ','ऋ'],
          ['ॅ','ॉ','ै','ो','ौ','ं','ः','ऺ','ऻ','ॄ'],
          ['ल्','ल्ल','जै','ज्ञ','ज्ञ','स','ग','ज्ञ','ड्ड','ब'],
          ['ऴ','ऴ','ऻ','ॅ','ॉ','?','न','र','ळ','ळ'],
          ['०','\\\\','\'','।','॰','\$','॥','ॐ']
        ];
      default:
        return _getHindiLayoutPage(0, selectedLetter: selectedLetter);
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
          ['ज्ञ','त्र','स्त','द्ध','ड्ड','ज्ज','श्र','क्र','ग्र','द्र'],
          ['ध्र','प्र','ब्र','भ्र','म्र','फ्र','व्र','त्क','त्त','ह्म'],
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
  
  /// Get numeric and symbol layout
  static List<List<String>> getNumericLayout() {
    return [
      ['1','2','3','4','5','6','7','8','9','0'],
      ['@','#','\$','_','&','-','+','(',')','/',],
      ['*','"','\'',':',';','!','?','~','<','>'],
      ['more','=','{','}','[',']','\\','%','^'],
    ];
  }

  /// Check if a character is a consonant that can take vowel attachments
  static bool isConsonant(String char, String language) {
    if (language == 'hi' || language == 'mr') {
      // List of common Devanagari consonants (including nukta variations)
      const consonants = [
        'क','ख','ग','घ','ङ','च','छ','ज','झ','ञ',
        'ट','ठ','ड','ढ','ण','त','थ','द','ध','न',
        'प','फ','ब','भ','म','य','र','ल','व','श',
        'ष','स','ह','ळ','ड़','ढ़','फ़','ज़','ख़'
      ];
      return consonants.contains(char);
    }
    return false;
  }

  /// Get display name for language code
  static String getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'hi': return 'हिंदी';
      case 'mr': return 'मराठी';
      default: return code.toUpperCase();
    }
  }

  /// Get maximum layout pages for a language
  static int getMaxLayoutPages(String language) {
    switch (language) {
      case 'hi':
      case 'mr':
        return 4;
      case 'en':
      default:
        return 1;
    }
  }
}