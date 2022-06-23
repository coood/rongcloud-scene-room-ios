//
//  RCSceneMusicExtension+String.swift
//  Alamofire
//
//  Created by shaoshuai on 2022/5/23.
//

import Foundation

extension String {
    func md5() -> String {
        guard self.count > 0 else {
            fatalError("md5加密无效的字符串")
        }
        let cCharArray = self.cString(using: .utf8)
        var uint8Array = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(cCharArray, CC_LONG(cCharArray!.count - 1), &uint8Array)
        let data = Data(bytes: &uint8Array, count: Int(CC_MD5_DIGEST_LENGTH))
        let base64String = data.base64EncodedString()
        return base64String.replacingOccurrences(of: "/", with: "")
    }
}
