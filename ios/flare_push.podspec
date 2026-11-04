Pod::Spec.new do |s|
  s.name             = 'flare_push'
  s.version          = '0.3.0'
  s.summary          = 'Flutter client for the Flare push notification service.'
  s.homepage         = 'https://github.com/pulloxz/flare_push'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Flare' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'flare_push/Sources/flare_push/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
end
