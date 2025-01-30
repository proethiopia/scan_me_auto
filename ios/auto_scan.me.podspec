

Pod::Spec.new do |s|
  s.name             = 'auto_scan.me'  # Must match filename (doc_scan_me.podspec)
  s.version          = '0.0.2'
  s.summary          = 'Document Scanner Plugin for Flutter'
  s.description      = <<-DESC
A Flutter plugin for document scanning using MLKit Document Scanner API.
Supports both iOS and Android platforms.
                       DESC
  s.homepage         = 'https://github.com/proethiopia/doc_scan_me'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :git => 'https://github.com/proethiopia/doc_scan_me.git', :tag => s.version.to_s }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end