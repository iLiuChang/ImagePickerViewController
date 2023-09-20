Pod::Spec.new do |s|
  s.name         = "ImagePickerViewController"
  s.version      = "1.0.0"
  s.summary      = "paging menu"
  s.homepage     = "https://github.com/iLiuChang/ImagePickerViewController"
  s.license      = "MIT"
  s.authors      = { "iLiuChang" => "iliuchang@foxmail.com" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/iLiuChang/ImagePickerViewController.git", :tag => s.version }
  s.resource_bundles = { 'ImagePickerViewController' => ['Source/Images/*.{png}'] }
  s.requires_arc = true
  s.swift_version = "5.0"
  s.source_files = "Source/*.{swift}"
end
