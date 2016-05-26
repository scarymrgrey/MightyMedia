
//
//  AudioAssetsWithEffects.swift
//  TelePic
//
//  Created by Victor Gelmutdinov on 04/05/16.
//  Copyright © 2016 BRDDMH. All rights reserved.
//

import Foundation


class CacheableEngine : Hashable {
    var Engine : AVAudioEngine
    var trackUrl : NSURL
    init(engine : AVAudioEngine,url:NSURL){
        Engine = engine
        trackUrl = url
    }
    var hashValue : Int {
        get {
            return "\(self.Engine),\(self.trackUrl)".hashValue
        }
    }
}
func ==(lhs: CacheableEngine  , rhs: CacheableEngine) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

class AudioUnitsWithFilters : PAudioTracks{
  
    private var enginesArray : [Int : AVAudioEngine] = [Int : AVAudioEngine]()
    private var cachedEnginesDictionary : [CacheableEngine:String] = [CacheableEngine:String]()
    private func processWithEngine(engine : AVAudioEngine,trackUrl : NSURL) -> NSURL {
        let renderer = ObjectiveCAudioRenderer()
        let cache = CacheableEngine(engine: engine,url: trackUrl)
        if(cachedEnginesDictionary[cache] == nil){
            cachedEnginesDictionary[cache] = renderer.renderAudioAndWriteToFile(engine, trackUrl)
        }
        return NSURL(fileURLWithPath: cachedEnginesDictionary[cache]!)
    }
    
    
    func presetRoboEngine(url : NSURL) -> AVAudioEngine {
        let engine = AVAudioEngine()
        let playerA = AVAudioPlayerNode()
        let playerB = AVAudioPlayerNode()
        playerA.volume = 1.0
        playerB.volume = 1.0
        
        engine.attachNode(playerA)
        engine.attachNode(playerB)
        
        let distortion = AVAudioUnitDistortion()
        engine.attachNode(distortion)
        
        let reverb = AVAudioUnitReverb()
        engine.attachNode(reverb)
        
        
        let mixer = engine.mainMixerNode
        engine.connect(playerA, to: distortion, format: distortion.outputFormatForBus(0))
        engine.connect(distortion, to: mixer, format: mixer.outputFormatForBus(0))
        
        engine.connect(playerB, to: reverb, format: reverb.outputFormatForBus(0))
        engine.connect(reverb, to: mixer, format: mixer.outputFormatForBus(0))
        
        distortion.loadFactoryPreset(AVAudioUnitDistortionPreset.SpeechRadioTower)
        distortion.wetDryMix = 25
        reverb.loadFactoryPreset(AVAudioUnitReverbPreset.MediumChamber)
        reverb.wetDryMix = 50
        do{
            try engine.start()
            
        } catch{
        }
        
        do{
            let file = try AVAudioFile(forReading: url)
            playerA.scheduleFile(file, atTime: nil, completionHandler: nil)
            
            
        } catch _{
            
        }
        
        playerA.play()
        playerB.play()
        engine.pause()
        return engine
    }
    
    
    func presetPitchEngine(url : NSURL) -> AVAudioEngine {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        
        player.volume = 1.0
        
        
        engine.attachNode(player)
        
        
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = -700
        pitch.rate = 1
        engine.attachNode(pitch)
        
        let mixer = engine.mainMixerNode
        
        engine.connect(player, to: pitch, format: pitch.outputFormatForBus(0))
        engine.connect(pitch, to: mixer, format: mixer.outputFormatForBus(0))
        
        do{
            try engine.start()
            
        } catch{
        }
        
        do{
            let file = try AVAudioFile(forReading: url)
            player.scheduleFile(file, atTime: nil, completionHandler: nil)
            
            
        } catch _{
            
        }
        
        player.play()
        
        engine.pause()
        return engine
    }
    
    func presetPitchUpEngine(url : NSURL) -> AVAudioEngine {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        
        player.volume = 1.0
        
        
        engine.attachNode(player)
        
        
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = 1000
        pitch.rate = 1.0
        engine.attachNode(pitch)
        
        let mixer = engine.mainMixerNode
        
        engine.connect(player, to: pitch, format: pitch.outputFormatForBus(0))
        engine.connect(pitch, to: mixer, format: mixer.outputFormatForBus(0))
        
        do{
            try engine.start()
            
        } catch{
        }
        
        do{
            let file = try AVAudioFile(forReading: url)
            player.scheduleFile(file, atTime: nil, completionHandler: nil)
            
            
        } catch _{
            
        }
        player.play()
        engine.pause()
        return engine
    }

    func associateEnginesAndTracks(effectsDictionary : (TrackNumber : Int,Engine : AVAudioEngine)){
        enginesArray[effectsDictionary.TrackNumber] = effectsDictionary.Engine
    }
    func removeEngineForTrack(number number : Int)
    {
        enginesArray[number] = nil
    }
    func InsertAudioTracks(audioArray : [AudioTrack],mixComposition : AVMutableComposition){
        for (index, audioUnit) in audioArray.enumerate(){
            var audioAsset : AVAsset?
            if enginesArray[index] != nil{
                let effPath = processWithEngine(enginesArray[index]! , trackUrl: audioUnit.AudioUrl)
                print(audioUnit.AudioUrl)
                audioAsset = AVAsset(URL: effPath)
            }else {
                audioAsset  = AVAsset(URL: audioUnit.AudioUrl)
            }
            
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
