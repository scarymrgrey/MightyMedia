//
//  DirectoryManager.swift
//  TelePic
//
//  Created by Victor Gelmutdinov on 05/05/16.
//  Copyright © 2016 BRDDMH. All rights reserved.
//

import Foundation


class DirectoryManager {
    enum DirectoryType{
        case Temp(AssetType)
        case Video
        enum AssetType {
            case Audio
            case Video
        }
    }
    func GetUniquePath( inDirectory dirType : DirectoryType) ->NSURL{
       // let dateFormatter = NSDateFormatter()
        //dateFormatter.dateStyle = .ShortStyle
       // dateFormatter.timeStyle = .LongStyle
        let uid = NSUUID().UUIDString
        var savePath : String
        
        switch dirType {
        case .Temp(let type):
            let path = NSTemporaryDirectory() as String
            if(type == .Audio){
                savePath = (path as NSString).stringByAppendingPathComponent("temp-\(uid).m4a")
            }else {
                savePath = (path as NSString).stringByAppendingPathComponent("temp-\(uid).mov")
            }
            
            break
        case .Video:
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            savePath = (documentDirectory as NSString).stringByAppendingPathComponent("videoWithClips\(uid).mov")
        }
     
        return NSURL(fileURLWithPath: savePath)
    }
}