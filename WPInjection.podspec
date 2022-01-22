#
# Be sure to run `pod lib lint WPInjection.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WPInjection'
  s.version          = '0.2.0'
  s.summary          = '简单易用的轻量依赖注入框架'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/stevepeng13/WPInjection'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'stevepeng13' => 'stevepeng13@outlook.com' }
  s.source           = { :git => 'git@github.com:codernash/WPInjection.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'WPInjection/Classes/**/*'

   s.dependency 'WPDelegates'
end
