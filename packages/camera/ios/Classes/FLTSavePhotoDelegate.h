//
//  FLTSavePhotoDelegate.h
//  camera
//
//  Created by libin14 on 2020/9/2.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

static FlutterError *getFlutterError(NSError *error) {
  return [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %d", (int)error.code]
                             message:error.localizedDescription
                             details:error.domain];
}

@interface FLTSavePhotoDelegate : NSObject <AVCapturePhotoCaptureDelegate>
@property(readonly, nonatomic) NSString *path;
@property(readonly, nonatomic) FlutterResult result;
@property(readonly, nonatomic) CMMotionManager *motionManager;
@property(readonly, nonatomic) AVCaptureDevicePosition cameraPosition;

- (instancetype)initWithPath:(NSString *)path
                      result:(FlutterResult)result
               motionManager:(CMMotionManager *)motionManager
              cameraPosition:(AVCaptureDevicePosition)cameraPosition;
@end

NS_ASSUME_NONNULL_END
