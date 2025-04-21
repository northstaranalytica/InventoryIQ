# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target 'InventoryIQ' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for InventoryIQ
  pod 'SwiftCSV'
  pod 'SnapKit'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'IQKeyboardManagerSwift'
  pod 'Toast-Swift'
  pod 'MBProgressHUD'
  pod 'ZLPhotoBrowser'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      # Fix for Xcode 14+ and libarclite issue
      config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
    end
  end
end
