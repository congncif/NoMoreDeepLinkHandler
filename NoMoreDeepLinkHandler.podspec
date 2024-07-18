Pod::Spec.new do |s|
  s.name = "NoMoreDeepLinkHandler"
  s.version = "1.0.0"
  s.summary = "A short description of NoMoreDeepLinkHandler."

  s.homepage = "https://github.com/congncif/NoMoreDeepLinkHandler"

  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Nguyen Chi Cong" => "congnc.if@gmail.com" }
  s.source = { :git => "https://github.com/congncif/NoMoreDeepLinkHandler.git", :tag => s.version.to_s }

  s.ios.deployment_target = "12.0"

  s.source_files = "Sources/**/*.{swift,h,m}"
  
  s.resource_bundles = {'NoMoreDeepLinkHandler' => ['Sources/PrivacyInfo.xcprivacy']}
end
