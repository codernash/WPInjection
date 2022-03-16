Pod::Spec.new do |s|
  s.name             = 'List'
  s.version          = '0.1.0'
  s.summary          = 'List'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/stevepeng13/WPInjection'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'stevepeng13' => 'stevepeng13@outlook.com' }
  s.source           = { :git => 'https://github.com/stevepeng13/WPInjection.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = '**/*.{h,m}'
  
  s.dependency 'Protocol'
end
