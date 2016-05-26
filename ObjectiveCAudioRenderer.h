//
//  ViewController.h
//  AVAudioEngineOfflineRender
//
//  Created by Vladimir Kravchenko on 6/9/15.
//  Copyright (c) 2015 Vladimir S. Kravchenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVAudioMixerNode;
@class AVAudioFile;
@class AVAudioPlayer;
@class AVAudioEngine;
@interface ObjectiveCAudioRenderer : NSObject 
- (NSString *)renderAudioAndWriteToFile :(AVAudioEngine*) engine
                                        :(NSURL*) fileURL;
@end

