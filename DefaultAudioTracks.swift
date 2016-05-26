//
//  DefaultAudioTracks.swift
//  TelePic
//
//  Created by Victor Gelmutdinov on 05/05/16.
//  Copyright © 2016 BRDDMH. All rights reserved.
//

import Foundation

class DefaultAudioAssets: PAudioTracks {
    func InsertAudioTracks(audioArray : [AudioTrack],mixComposition : AVMutableComposition){
        for audioUnit in audioArray{
            
            let audioAsset : AVAsset? = AVAsset(URL: audioUnit.AudioUrl)
            if let loadedAudioAsset = audioAsset {
                let audio = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 0)
                do {
                  
                    try audio.insertTimeRange(CMTimeRangeMake(audioUnit.FromTime, audioUnit.ToTime),
                                              ofTrack: loadedAudioAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                                              atTime: audioUnit.AtTime)
                } catch _ {
                    print("Failed to load audio track")
                }
            }
        }
    }
}