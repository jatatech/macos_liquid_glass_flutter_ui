#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint macos_liquid_glass_ui.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'macos_liquid_glass_ui'
  s.version          = '0.9.0.dev.1'
  s.summary          = 'Native functionality for the macos_liquid_glass_ui Flutter package.'
  s.description      = <<-DESC
macos_liquid_glass_ui is a Flutter package that provides widgets and themes implementing the current macOS design language.
                       DESC
  s.homepage         = 'https://github.com/jatatech/macos_liquid_glass_flutter_ui'
  s.license          = { :file => '../LICENSE', :type => 'MIT' }
  s.author           = { 'GroovinChip' => 'groovinchip@gmail.com' }
  s.source           = { :git => 'https://github.com/jatatech/macos_liquid_glass_flutter_ui.git',
	                       :branch => 'main' }
  s.source_files = 'macos_liquid_glass_ui/Sources/macos_liquid_glass_ui/**/*.swift'
  s.resource_bundles = {'macos_liquid_glass_ui_privacy' => ['macos_liquid_glass_ui/Sources/macos_liquid_glass_ui/Resources/PrivacyInfo.xcprivacy']}
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
