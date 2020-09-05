//
//  FLTCam.h
//  camera
//
//  Created by libin14 on 2020/9/2.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>
#import "FLTImageStreamHandler.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, ResolutionPreset) {
  veryLow,
  low,
  medium,
  high,
  veryHigh,
  ultraHigh,
  max,
};

@interface FLTCam : NSObject <FlutterTexture, FlutterStreamHandler>

@property(nonatomic, copy) void (^onFrameAvailable)(void);
@property(nonatomic) FlutterEventChannel *eventChannel;
@property(readonly, nonatomic) CGSize previewSize;
@property(readonly, nonatomic) CGSize captureSize;

- (instancetype)initWithCameraName:(NSString *)cameraName
                  resolutionPreset:(NSString *)resolutionPreset
                       enableAudio:(BOOL)enableAudio
                     dispatchQueue:(dispatch_queue_t)dispatchQueue
                             error:(NSError **)error;
- (void)close;
- (void)start;
- (void)startImageStreamWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;
- (void)stopImageStream;
- (void)pauseVideoRecording;
- (void)resumeVideoRecording;
- (void)captureToFile:(NSString *)path result:(FlutterResult)result API_AVAILABLE(ios(10));
- (void)setUpCaptureSessionForAudio;
- (void)startVideoRecordingAtPath:(NSString *)path result:(FlutterResult)result;
- (void)stopVideoRecordingWithResult:(FlutterResult)result;
@end

NS_ASSUME_NONNULL_END
