//
//  VoiceRoomManager.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/3.
//

public enum RCScene: Int, CaseIterable {
    case audioRoom  = 1
    case audioCall  = 11
    case videoCall  = 10
    case liveVideo  = 3
    case radioRoom  = 2
    case gameRoom   = 12
    case community  = 20
    case musicKTV   = 30
    case privateCall = 40
}

public enum SceneRoomUserType {
    case creator
    case manager
    case audience
}

public class SceneRoomManager {
    public static let shared = SceneRoomManager()
    
    public let queue = DispatchQueue(label: "scene_room_queue")
    
    /// 当前场景类型，进入room时，用room.roomType
    public static var scene = RCScene.audioRoom
    /// 当前所在房间
    public var currentRoom: RCSceneRoom?
    /// 管理员
    public var managers = [String]()
    /// 房间背景
    public var backgrounds = [String]()
    /// 屏蔽词
    public var forbiddenWords = [String]()
    /// 在麦位上的用户
    public var seats = [String]()
    
    public func clear() {
        seats.removeAll()
        managers.removeAll()
        backgrounds.removeAll()
        forbiddenWords.removeAll()
    }
}
