#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint calendar_manager.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'calendar_manager'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for creating calenders and events for the device default calender.'
  s.description      = <<-DESC
A Flutter plugin for creating calenders and events for the device default calender.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
