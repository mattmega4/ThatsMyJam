# Uncomment the next line to define a global platform for your project
 platform :ios, '12.1'


target 'ThatsMyJam' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ThatsMyJam

  pod 'AcknowList'
  pod 'ChameleonFramework/Swift'
  pod 'Crashlytics', '~> 3.14.0'
  pod 'Fabric', '~> 1.10.2'
  pod 'Firebase/Analytics'
  pod 'Firebase/Core'
  pod 'Firebase/Performance'
  pod 'MarqueeLabel'
  pod 'mailgun'
  pod 'UITextView+Placeholder'


  target 'ThatsMyJamTests' do
    inherit! :search_paths
    # Pods for testing
  end
  



end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
    end
  end
end


