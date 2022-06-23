
Pod::Spec.new do |s|
  
  # 1 - Info
  s.name             = 'RCSceneRoom'
  s.version          = '0.0.3.6'
  s.summary          = 'Scene Room'
  s.description      = "Scene Room module"
  s.homepage         = 'https://github.com/rongcloud'
  s.license      = { :type => "Copyright", :text => "Copyright 2022 RongCloud" }
  s.author           = { 'shaoshuai' => 'shaoshuai@rongcloud.cn' }
  s.source           = { :git => 'https://github.com/rongcloud-community/rongcloud-scene-room-ios.git', :tag => s.version.to_s }
  
  # 2 - Version
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.static_framework = true
  
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'VALID_ARCHS' => 'arm64 x86_64'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  # 3 - subspecs
  s.default_subspec = 'RCSceneRoom'
  
  # RCSRBase
  s.subspec 'RCSRBase' do |base|
    # 1 - source
    base.source_files = 'RCSceneRoom/RCSRBase/**/*.{h,swift}'
    
    # 2 - dependency
    base.dependency 'Moya'
    base.dependency 'SwiftyBeaver'
  end
  
  s.subspec 'RCSRAssets' do |assets|
    # 1 - source
    assets.source_files = 'RCSceneRoom/RCSRAssets/**/*.{h,m,swift}'
    
    # 2 - resource
    assets.resource_bundles = {
      'RCSceneRoom' => ['RCSceneRoom/RCSRAssets/Assets/*.xcassets']
    }
  end
  
  s.subspec 'RCSceneMessage' do |message|
    # 1 - source
    message.source_files = 'RCSceneRoom/RCSceneMessage/**/*.{h,m,swift}'
    message.public_header_files = 'RCSceneRoom/RCSceneMessage/**/*.{h}'
    
    # 2 - dependency
    # suggestion version >= 5.1.8
    message.dependency 'RongCloudIM/IMLib'
  end
  
  s.subspec 'RCSceneService' do |service|
    # 1 - source
    service.source_files = 'RCSceneRoom/RCSceneService/**/*.{h,m,swift}'
    
    # 2 - dependency
    service.dependency 'ReachabilitySwift'
    service.dependency 'RCSceneRoom/RCSRBase'
  end
  
  s.subspec 'RCSRPassword' do |password|
    # 1 - source
    password.source_files = 'RCSceneRoom/RCSRPassword/**/*.{h,swift}'
    
    # 2 - dependency
    password.dependency 'SnapKit'
    password.dependency 'RCSceneRoom/RCSRBase'
    password.dependency 'RCSceneRoom/RCSRAssets'
  end
  
  s.subspec 'RCSRUserControl' do |control|
    # 1 - source
    control.source_files = 'RCSceneRoom/RCSRUserControl/**/*.{h,swift}'
    
    # 2 - dependency
    control.dependency 'SnapKit'
    control.dependency 'Reusable'
    control.dependency 'Kingfisher'
    control.dependency 'SVProgressHUD'
    control.dependency 'RCSceneRoom/RCSRBase'
    control.dependency 'RCSceneRoom/RCSRAssets'
    control.dependency 'RCSceneRoom/RCSceneService'
  end
  
  s.subspec 'RCSRChat' do |chat|
    # 1 - source
    chat.source_files = 'RCSceneRoom/RCSRChat/**/*.{h,swift}'
    
    # 2 - dependency
    chat.dependency 'SVProgressHUD'
    # suggestion version >= 5.1.8
    chat.dependency 'RongCloudOpenSource/IMKit'
    chat.dependency 'RCSceneRoom/RCSceneService'
  end
  
  s.subspec 'RCSceneGift' do |gift|
    # 1 - source
    gift.source_files = 'RCSceneRoom/RCSceneGift/Classes/**/*'
    
    # 2 - resource
    gift.resource_bundles = {
      'RCSceneGift' => ['RCSceneRoom/RCSceneGift/Assets/*.xcassets']
    }
    
    # 3 - dependency
    gift.dependency 'SnapKit'
    gift.dependency 'Reusable'
    gift.dependency 'Kingfisher'
    gift.dependency 'SVProgressHUD'
    gift.dependency 'RCSceneRoom/RCSceneMessage'
    gift.dependency 'RCSceneRoom/RCSceneService'
    
  end
  
  s.subspec 'RCSceneMusic' do |music|
    # 1 - source
    music.source_files = 'RCSceneRoom/RCSceneMusic/**/*'
    
    # 2 - config
    
    # 3 - dependency
    music.dependency 'SVProgressHUD'
    music.dependency 'RCMusicControlKit'
    music.dependency 'RongCloudRTC/RongRTCLib'
    music.dependency 'RCSceneRoom/RCSceneMessage'
    music.dependency 'RCSceneRoom/RCSceneService'
  end
  
  s.subspec 'RCSceneRoomSetting' do |setting|
    # 1 - source
    setting.source_files = 'RCSceneRoom/RCSceneRoomSetting/Classes/**/*'
    
    # 2 - resource
    setting.resource_bundles = {
      'RCSceneRoomSetting' => ['RCSceneRoom/RCSceneRoomSetting/Assets/*.xcassets']
    }
    
    # 3 - dependency
    setting.dependency 'Reusable'
    setting.dependency 'RCSceneRoom/RCSRPassword'
    setting.dependency 'RCSceneRoom/RCSceneService'
  end
  
  s.subspec 'RCSceneAnalytics' do |analytics|
    # 1 - source
    analytics.source_files = 'RCSceneRoom/RCSceneAnalytics/Classes/**/*'
    
    # 2 - dependency
    analytics.dependency 'SensorsAnalyticsSDK'
    analytics.dependency 'RCSceneRoom/RCSceneRoomSetting'
  end
  
  s.subspec 'RCSceneRoom' do |room|
    # 1 - source
    room.source_files = 'RCSceneRoom/RCSceneRoom/**/*'
    
    # 2 - dependency
    room.dependency 'RCSceneChatroomKit'
    room.dependency 'RCSceneRoom/RCSRChat'
    room.dependency 'RCSceneRoom/RCSceneGift'
    room.dependency 'RCSceneRoom/RCSceneMusic'
    room.dependency 'RCSceneRoom/RCSRUserControl'
    room.dependency 'RCSceneRoom/RCSceneRoomSetting'
  end
  
end
