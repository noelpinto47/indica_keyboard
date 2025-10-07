#
# IndicaKeyboard iOS Native Plugin with High-Performance Text Processing
# Optimized for Hindi, Marathi, and English with 3-5x performance improvements
#
Pod::Spec.new do |s|
  s.name             = 'indica_keyboard'
  s.version          = '0.1.0'
  s.summary          = 'High-performance multilingual keyboard with native iOS optimization'
  s.description      = <<-DESC
IndicaKeyboard provides native iOS text processing for Hindi, Marathi, and English languages.
Features ultra-fast conjunct consonant formation, multi-tier caching, and automatic performance
optimization with 3-5x speed improvements over pure Dart implementations.
                       DESC
  s.homepage         = 'https://github.com/noelpinto47/indica_keyboard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Noel Pinto' => 'noelpinto47@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Optimization flags for performance
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'SWIFT_OPTIMIZATION_LEVEL' => '-O',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'GCC_OPTIMIZATION_LEVEL' => '3'
  }
  s.swift_version = '5.0'

  # Enable privacy manifest for App Store compliance
  s.resource_bundles = {'indica_keyboard_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
  
  # Frameworks required for performance optimizations
  s.frameworks = 'Foundation', 'UIKit'
  s.ios.deployment_target = '13.0'
  
  # Compiler flags for maximum performance
  s.compiler_flags = '-DINDICA_PERFORMANCE_OPTIMIZED'
end
