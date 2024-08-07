Pod::Spec.new do |s|
  s.name         = "ImagePickerViewController"
  s.version      = "1.4.1"
  s.summary      = "A view controller that manages the system interfaces for taking pictures and choosing items from the user’s media library."
  s.homepage     = "https://github.com/iLiuChang/ImagePickerViewController"
  s.license      = "MIT"
  s.authors      = { "iLiuChang" => "iliuchang@foxmail.com" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/iLiuChang/ImagePickerViewController.git", :tag => s.version }
  s.resource_bundles = { 'ImagePickerViewController' => ['Source/Images/*.{png}','PrivacyInfo.xcprivacy'] }
  s.requires_arc = true
  s.swift_version = "5.0"
  s.source_files = "Source/*.{swift}"
end
