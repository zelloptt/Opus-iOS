Pod::Spec.new do |spec|
  spec.name         = "zello-opus-ios"
  spec.summary      = "A totally open, royalty-free, highly versatile audio codec."
  spec.description  =<<-DESC
Build scripts and a binary .xcframework for the Opus audio codec on iOS.
DESC
  spec.version      = "1.0.0"
  spec.homepage     = "https://github.com/zelloptt/Opus-iOS"
  spec.authors      = { "Greg Cooksey" => "greg@zello.com" }
  spec.source       = { :git => "https://github.com/zelloptt/Opus-iOS.git", :tag => "v" + spec.version.to_s }
  spec.platform     = :ios, "12.1"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.vendored_frameworks = "opus.xcframework"
  spec.changelog = 'CHANGELOG.md'
  # TODO: Create pod readme file
  #  spec.readme = ''
end
