//
//  MusicDataSourceMediator.swift
//  RCE
//
//  Created by xuefeng on 2021/11/29.
//

import AVFoundation
import SVProgressHUD

public class RCSMusicDataSource: NSObject, RCMusicEngineDataSource {
    
    public static let instance = RCSMusicDataSource()
    
    var musics: Array<MusicInfo>?
    
    //当前房间列表的所有音乐，结束直播时需要清空该列表
    var ids: Set<String> = Set()
    
    var groupId: String?
    
    static func musicDir() -> String? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("rcm_musics")
        var isDirectory: ObjCBool = false
        let isExists = FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) && isDirectory.boolValue;
        if (!isExists) {
            do {
                try FileManager.default.createDirectory(atPath: fileURL.path,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
            } catch {
                print("create rcm_musics fail");
            }
        }
        return fileURL.path
    }
    
    public func dataSourceInitialized() {
        guard let config = musicConfig else { return }
        HFOpenApiManager.shared()
            .registerApp(withAppId: config.appId,
                         serverCode: config.serverCode,
                         clientId: config.clientId,
                         version: config.version) { _ in
                print("register hifive success")
            } fail: { _ in
                fatalError("register hifive failed")
            }
    }
    
    public func fetchCategories(_ completion: @escaping ([Any]?) -> Void) {
        
        DispatchQueue.global().async {
            
            let sem = DispatchSemaphore.init(value: 0)
            
            HFOpenApiManager.shared().channel { response in
                guard let channels = response as? Array<Dictionary<String, String>> else {
                    return completion(nil)
                }
                if (channels.count > 0) {
                    let channel = channels[0]
                    self.groupId = channel["groupId"];
                }
                sem.signal()
            } fail: { error in
                print("RCSMusicDataSource fetch groupId fail")
                SVProgressHUD.showError(withStatus: "获取歌曲类别失败")
                sem.signal()
                return completion(nil)
            }
            
            let _ = sem.wait(timeout: .now() + 20)
            
            guard let groupId = self.groupId else {
                print("RCSMusicDataSource groupId is nil")
                return completion(nil)
            }
            
            HFOpenApiManager.shared().channelSheet(withGroupId: groupId, language: "0", recoNum: nil, page: "1", pageSize: "100") { response in
                guard let response = response as? [AnyHashable : Any], let data = RCMusicSheetData.yy_model(with: response), let records = data.record else {
                    return completion(nil)
                }
                
                var result = Array<MusicCategoryInfo>()
                
                if (records.count > 0) {
                    for record in records {
                        let categoryInfo = MusicCategoryInfo()
                        categoryInfo.categoryName = record.sheetName
                        categoryInfo.categoryId = record.sheetId?.stringValue
                        result.append(categoryInfo)
                    }
                }
                completion(result)
                print("RCSMusicDataSource fetch categories success")
            } fail: { error  in
                completion(nil)
                print("RCSMusicDataSource fetch categories failed \(error.debugDescription)")
            }
        }
    }
    
    
    public func fetchOnlineMusics(byCategoryId categoryId: String, completion: @escaping ([Any]?) -> Void) {
        HFOpenApiManager.shared().sheetMusic(withSheetId: categoryId, language: "0", page: "1", pageSize: "100") { response in
            guard let response = response as? [AnyHashable : Any], let data = RCMusicData.yy_model(with: response), let records = data.record else {
                SVProgressHUD.showError(withStatus: "在线歌曲获取失败")
                return completion(nil)
            }
            var result = Array<MusicInfo>()
            
            if (records.count > 0) {
                for record in records {
                    let musicInfo = MusicInfo()
                    musicInfo.coverUrl = record.coverUrl;
                    musicInfo.musicName = record.musicName;
                    musicInfo.author = record.authorName;
                    musicInfo.albumName = record.albumName;
                    musicInfo.musicId = record.musicId;
                    result.append(musicInfo)
                }
            }
            completion(result)
            print("RCSMusicDataSource fetch musics success")
        } fail: { error in
            completion(nil)
            print("RCSMusicDataSource fetch musics failed \(error?.localizedDescription ?? "")")
            SVProgressHUD.showError(withStatus: "在线歌曲获取失败")
        }
    }
    
    
    public func fetchCollectMusics(_ completion: @escaping ([Any]?) -> Void) {
        guard let roomId = currentRoom?.roomId else {
            print("RCSMusicDataSource fetch collection musics failed roomId is nil")
            SVProgressHUD.showError(withStatus: "收藏歌曲获取失败，roomId不能为空")
            return completion(nil)
        }
    
        musicService.musicList(roomId: roomId, type: 1) { result in
            switch result.map(RCSceneWrapper<[VoiceRoomMusic]>.self) {
                case let .success(wrapper):
                    if let musics = wrapper.data {
                        var _result = Array<MusicInfo>()
                        for music in musics {
                            let musicInfo = MusicInfo()
                            musicInfo.fileUrl = music.url
                            musicInfo.musicName = music.name
                            musicInfo.author = music.author
                            musicInfo.albumName = "无"
                            musicInfo.size = music.size
                            musicInfo.musicId = music.thirdMusicId
                            musicInfo.coverUrl = music.backgroundUrl
                            musicInfo.id = music.id
                            _result.append(musicInfo)
                            if (musicInfo.musicId != nil) {
                                RCSMusicDataSource.instance.ids.insert(musicInfo.musicId!)
                            }
                        }
                        if (RCSMusicDelegate.instance.autoPlayMusic) {
                            RCSMusicDelegate.instance.autoPlayMusic = false
                            if let info = _result.first {
                                let _ = RCSMusicPlayer.instance.startMixing(with: info)
                            }
                        }
                        RCSMusicDataSource.instance.musics = _result
                        completion(_result)
                    } else {
                        completion(nil)
                        SVProgressHUD.showError(withStatus: "收藏歌曲获取失败，roomId不能为空")
                    }
                case let .failure(error):
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                    completion(nil)
            }
        }
    }
    

    
    public func fetchMusicDetail(with info: RCMusicInfo, completion: @escaping (RCMusicInfo?) -> Void) {
        guard let info = info as? MusicInfo, let musicId = info.musicId else {
            print("参数错误，音乐ID为空")
            SVProgressHUD.showError(withStatus: "参数错误，音乐ID为空")
            completion(nil)
            return
        }
        
        //歌曲链接中带有服务域名证明是我们自己存储的音乐直接返回音乐信息，不需要跟曲库获取最新的播放链接
        if let url = info.fileUrl, url.contains("rongcloud") {
            completion(info)
            return
        }
        
        
        HFOpenApiManager.shared().trafficHQListen(withMusicId: musicId, audioFormat: nil, audioRate: nil) { response in
            guard let response = response as? [AnyHashable : Any], let detail = RCMusicDetail.yy_model(with: response) else {
                return completion(nil)
            }
            info.fileUrl = detail.fileUrl
            info.size = ByteCountFormatter.string(fromByteCount: Int64(detail.fileSize), countStyle: .file)
            completion(info)
        } fail: { error in
            completion(nil)
            print("RCSMusicDataSource fetch music detail failed \(error?.localizedDescription ?? "")")
            SVProgressHUD.showError(withStatus: "歌曲详情获取失败")
        }
    }
    
    public func fetchSearchResult(withKeyWord keyWord: String, completion: @escaping ([Any]?) -> Void) {
        
        HFOpenApiManager.shared().searchMusic(withTagIds: nil, priceFromCent: nil, priceToCent: nil, bpmFrom: nil, bpmTo: nil, durationFrom: nil, durationTo: nil, keyword: keyWord, language: "0", searchFiled: nil, searchSmart: nil, page: "1", pageSize: "100") { response in
            guard let response = response as? [AnyHashable : Any], let data = RCMusicData.yy_model(with: response), let records = data.record else {
                return completion(nil)
            }
            
            var result = Array<MusicInfo>()
            
            if (records.count > 0) {
                for record in records {
                    let info = MusicInfo()
                    info.coverUrl = record.coverUrl
                    info.musicName = record.musicName
                    info.author = record.authorName
                    info.albumName = record.albumName
                    info.musicId = record.musicId
                    result.append(info)
                }
            }
            completion(result)
        } fail: { error in
            completion(nil)
            print("RCSMusicDataSource fetch search result failed \(error?.localizedDescription ?? "")")
            SVProgressHUD.showError(withStatus: "获取搜索结果失败")
        }
    }
    
    public func fetchRoomPlayingMusicInfo(completion: @escaping (MusicInfo?) -> Void) {
        guard let roomId = currentRoom?.roomId else {
            print("获取直播间正在播放的音乐信息失败，roomId不能为空")
            return completion(nil)
        }
        musicService.fetchRoomPlayingMusicInfo(roomId: roomId) { result in
            switch result.map(RCSceneWrapper<BubbleMusicInfo>.self) {
                case let .success(wrapper):
                if let data = wrapper.data {
                    print("获取直播间正在播放的音乐信息失败,数据为空")
                    let info = MusicInfo()
                    info.musicName = data.name
                    info.coverUrl = data.backgroundUrl
                    info.author = data.author
                    completion(info)
                } else {
                    completion(nil)
                }
                case let .failure(error):
                    print("获取直播间正在播放的音乐信息失败 error\(error)")
                    completion(nil)
            }
        }
    }
    
    public func musicIsExist(_ info: RCMusicInfo) -> Bool {
        guard let _ = RCSMusicDataSource.instance.musics, let musicId = info.musicId else {
            return false
        }
        
        return RCSMusicDataSource.instance.ids.contains(musicId)
    }
    
    public func fetchSoundEffects(completion: @escaping ([Any]?) -> Void) {

        let bundle = Bundle(for: RCMusicEngine.classForCoder())
        
        let resourcePath = bundle.resourcePath
        
        guard let resourcePath = resourcePath else {
            SVProgressHUD.showError(withStatus: "当前没有特效资源")
            return completion(nil)
        }
        
        let bundlePath = resourcePath + "/" + "RCMusicControlKit.bundle" + "/" + "Assets"
        
        let info1 = EffectInfo()
        info1.soundId = 1
        info1.filePath = bundlePath + "/intro_effect.mp3"
        info1.effectName = "进场"
        
        let info2 = EffectInfo()
        info2.soundId = 2
        info2.filePath = bundlePath + "/cheering_effect.mp3"
        info2.effectName = "欢呼"
        
        let info3 = EffectInfo()
        info3.soundId = 3
        info3.filePath = bundlePath + "/clap_effect.mp3"
        info3.effectName = "鼓掌"
        
        completion([info1,info2,info3])
    }
    
    
    public func addLocalMusic(_ rootViewController: UIViewController) {
        presentLocalMusicPicker(rootViewController)
    }
    
    fileprivate let availableAudioFileExtensions: [String] = [
        "aac", "ac3", "aiff", "au", "m4a", "wav", "mp3"
    ]
    
    @objc private func presentLocalMusicPicker(_ rootViewController: UIViewController) {
        if #available(iOS 14.0, *) {
            let types: [UTType] = availableAudioFileExtensions.compactMap { UTType(filenameExtension: $0) }
            let documentController = UIDocumentPickerViewController(forOpeningContentTypes: types)
            documentController.delegate = self
            rootViewController.present(documentController, animated: true, completion: nil)
        } else {
            let types = [
                "public.audio",
                "public.mp3",
                "public.mpeg-4-audio",
                "com.apple.protected-​mpeg-4-audio ",
                "public.ulaw-audio",
                "public.aifc-audio",
                "public.aiff-audio",
                "com.apple.coreaudio-​format"
            ]
            let documentController = UIDocumentPickerViewController(documentTypes: types, in: .open)
            documentController.delegate = self
            rootViewController.present(documentController, animated: true, completion: nil)
        }
    }
    
    public func clear() {
        RCSMusicDataSource.instance.ids.removeAll()
        RCSMusicDataSource.instance.musics = nil
    }
}

extension RCSMusicDataSource: UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first(where: { !availableAudioFileExtensions.contains($0.pathExtension) }) {
            return SVProgressHUD.showError(withStatus: "不支持的类型：" + url.pathExtension)
        }
        let musics = urls.compactMap {
            MusicInfo.localMusic($0)
        }
        
        DispatchQueue.global().async {
            if let music = musics.first {
                SVProgressHUD.show()
                RCSMusicDelegate.instance.addLocalMusic(music) { success in
                    if (success) {
                        SVProgressHUD.showSuccess(withStatus: "本地文件上传成功")
                    } else {
                        SVProgressHUD.showError(withStatus: "本地文件上传失败")
                    }
                }
            }
        }
        
    }
}
