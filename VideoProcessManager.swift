//
//  VideoProcessManager.swift
//  TelePic
//
//  Created by Victor Gelmutdinov on 30/04/16.
//  Copyright © 2016 BRDDMH. All rights reserved.
//

import Foundation


//
//  VideoWithMusicViewController.swift
//  TelePic
//
//  Created by Victor Gelmutdinov on 27/04/16.
//  Copyright © 2016 BRDDMH. All rights reserved.
//

import UIKit
import MediaPlayer
import EZAudio
class AudioTrack {
    var AudioUrl : NSURL!
    var AtTime : CMTime!
    var FromTime : CMTime!
    var ToTime : CMTime!
    
    init(url : NSURL,atTime : CMTime){
        self.AudioUrl = url
        self.AtTime = atTime
        self.FromTime = kCMTimeZero
        let asset = AVAsset(URL: url)
        self.ToTime = asset.duration
    }
    init(url : NSURL,atTime : CMTime,fromTime: CMTime,toTime:CMTime){
        self.AudioUrl = url
        self.AtTime = atTime
        self.FromTime = fromTime
        self.ToTime = toTime
    }
}
protocol PAudioTracks {
    func InsertAudioTracks(audioArray : [AudioTrack],mixComposition : AVMutableComposition)
}

class VideoProcessManager {
    
    //MARK: Constructor
    
    private let audioManager : PAudioTracks
    init(){
        self.audioManager = DefaultAudioAssets()
    }
    init(audioManager : PAudioTracks ){
        self.audioManager = audioManager
    }
    
    func trimAndExportAsset(assetURL:NSURL, savePath:NSURL , fromTime :Float , toTime : Float ,onComplete : Void -> Void) {
        
        let trimmedSoundFileURL = savePath
        print("saving to \(trimmedSoundFileURL.absoluteString)")
        let asset = AVAsset(URL: assetURL)
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        exporter!.shouldOptimizeForNetworkUse = true
        exporter!.outputFileType = AVFileTypeAppleM4A
        exporter!.outputURL = trimmedSoundFileURL
        
        let duration = CMTimeGetSeconds(asset.duration)
        
        let from = Float(duration) * (fromTime / 100.0)
        let to = Float(duration) * (toTime / 100.0)
        // e.g. the first 5 seconds
        let startTime = CMTimeMake(Int64(from), 1)
        let stopTime = CMTimeMake(Int64(to), 1)
        exporter!.timeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
        
        
        // do it
        exporter!.exportAsynchronouslyWithCompletionHandler({
            switch exporter!.status {
            case  AVAssetExportSessionStatus.Failed:
                print("export failed \(exporter!.error)")
            case AVAssetExportSessionStatus.Cancelled:
                print("export cancelled \(exporter!.error)")
            default:
                print("export complete")
                dispatch_async(dispatch_get_main_queue()){
                    onComplete()
                }
            }
        })
    }
    
    func exportFirstTrackToFile(videoAssetUrl : NSURL ,onComplete : NSURL -> Void) -> NSURL?{
        let videoAsset = AVURLAsset(URL: videoAssetUrl)
        let pathManager = DirectoryManager()
        let savePath = pathManager.GetUniquePath(inDirectory: .Temp(.Audio))
        // 2 - Video track
            guard let exporter = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetAppleM4A) else { return nil }
            exporter.outputURL = savePath
            exporter.outputFileType = AVFileTypeAppleM4A
            exporter.shouldOptimizeForNetworkUse = true
            exporter.timeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, videoAsset.duration)
            // 6 - Perform the Export
            exporter.exportAsynchronouslyWithCompletionHandler() {
                switch exporter.status{
                case  AVAssetExportSessionStatus.Failed:
                    print("export failed \(exporter.error)")
                case AVAssetExportSessionStatus.Cancelled:
                    print("export cancelled \(exporter.error)")
                default:
                    print("exportFirstTrackToFile() complete")
                    onComplete(savePath)
                }
            }
        
        return savePath
    }
    func mixAudios(audioArray : [AudioTrack] ,saveUrl:NSURL, onCompleteAsync : Void -> Void ){
        
        let mixComposition = AVMutableComposition()
   
        audioManager.InsertAudioTracks(audioArray, mixComposition: mixComposition)
        
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetAppleM4A) else { return }
        exporter.outputURL = saveUrl
        exporter.outputFileType = AVFileTypeAppleM4A
        exporter.shouldOptimizeForNetworkUse = true
        
        // 6 - Perform the Export
        exporter.exportAsynchronouslyWithCompletionHandler() {
            switch exporter.status{
            case  .Failed:
                print("failed \(exporter.error)")
            case .Cancelled:
                print("cancelled \(exporter.error)")
            default:
                print("complete")
                dispatch_async(dispatch_get_main_queue()){
                    onCompleteAsync()
                }
            }
        }
    }
    
    func mixVideoAndAudio(videoURL:NSURL,audioArray : [AudioTrack] ,saveUrl:NSURL, onCompleteAsync : Void -> Void ){
        
        let mixComposition = AVMutableComposition()
        let videoAsset = AVURLAsset(URL: videoURL)
        // 2 - Video track
        let firstTrack :AVMutableCompositionTrack  = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                                                                                                 preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            let vt:AVAssetTrack = videoAsset.tracksWithMediaType(AVMediaTypeVideo).last!
            try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration),
                                           ofTrack: vt,
                                           atTime: kCMTimeZero)
            
            mixComposition.tracksWithMediaType(AVMediaTypeVideo).last?.preferredTransform = vt.preferredTransform
        } catch _ {
            print("Failed to load video track")
        }
        
        audioManager.InsertAudioTracks(audioArray, mixComposition: mixComposition)
        
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPreset1280x720) else { return }
        exporter.outputURL = saveUrl
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        
        exporter.exportAsynchronouslyWithCompletionHandler() {
            switch exporter.status{
            case  .Failed:
                print("failed \(exporter.error)")
            case .Cancelled:
                print("cancelled \(exporter.error)")
            default:
                print("mixVideoAndAudio() complete")
                dispatch_async(dispatch_get_main_queue()){
                    onCompleteAsync()
                }
            }
        }
    }
}
