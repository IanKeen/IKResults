Pod::Spec.new do |spec|
  spec.name         = 'IKResults'
  spec.version      = '1.0'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/iankeen82/'
  spec.authors      = { 'Ian Keen' => 'iankeen82@gmail.com' }
  spec.summary      = 'Result and AsyncResult classes that offer composition and easy fail-fast or railway logic.'
  spec.source       = { :git => 'https://github.com/iankeen82/ikresults.git', :tag => spec.version.to_s }

  spec.source_files = 'IKResults/**/**.{h,m}'
  
  spec.requires_arc = true
  spec.platform     = :ios
  spec.ios.deployment_target = "7.0"
end
