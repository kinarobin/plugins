//
//  FLTSavePhotoDelegate.m
//  camera
//
//  Created by libin14 on 2020/9/2.
//

#import "FLTSavePhotoDelegate.h"


@implementation FLTSavePhotoDelegate {
  /// Used to keep the delegate alive until didFinishProcessingPhotoSampleBuffer.
  FLTSavePhotoDelegate *selfReference;
}

- (instancetype)initWithPath:(NSString *)path
                      result:(FlutterResult)result
               motionManager:(CMMotionManager *)motionManager
              cameraPosition:(AVCaptureDevicePosition)cameraPosition {
  self = [super init];
  NSAssert(self, @"super init cannot be nil");
  _path = path;
  _result = result;
  _motionManager = motionManager;
  _cameraPosition = cameraPosition;
  selfReference = self;
  return self;
}

- (void)captureOutput:(AVCapturePhotoOutput *)output
    didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer
                previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer
                        resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
                         bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings
                                   error:(NSError *)error API_AVAILABLE(ios(10)) {
  selfReference = nil;
  if (error) {
    _result(getFlutterError(error));
    return;
  }
  NSData *data = [AVCapturePhotoOutput
      JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer
                            previewPhotoSampleBuffer:previewPhotoSampleBuffer];
  UIImage *image = [UIImage imageWithCGImage:[UIImage imageWithData:data].CGImage
                                       scale:1.0
                                 orientation:[self getImageRotation]];
  // TODO(sigurdm): Consider writing file asynchronously.
  bool success = [UIImageJPEGRepresentation(image, 1.0) writeToFile:_path atomically:YES];
  if (!success) {
    _result([FlutterError errorWithCode:@"IOError" message:@"Unable to write file" details:nil]);
    return;
  }
  _result(nil);
}

- (UIImageOrientation)getImageRotation {
  float const threshold = 45.0;
  BOOL (^isNearValue)(float value1, float value2) = ^BOOL(float value1, float value2) {
    return fabsf(value1 - value2) < threshold;
  };
  BOOL (^isNearValueABS)(float value1, float value2) = ^BOOL(float value1, float value2) {
    return isNearValue(fabsf(value1), fabsf(value2));
  };
  float yxAtan = (atan2(_motionManager.accelerometerData.acceleration.y,
                        _motionManager.accelerometerData.acceleration.x)) *
                 180 / M_PI;
  if (isNearValue(-90.0, yxAtan)) {
    return UIImageOrientationRight;
  } else if (isNearValueABS(180.0, yxAtan)) {
    return _cameraPosition == AVCaptureDevicePositionBack ? UIImageOrientationUp
                                                          : UIImageOrientationDown;
  } else if (isNearValueABS(0.0, yxAtan)) {
    return _cameraPosition == AVCaptureDevicePositionBack ? UIImageOrientationDown /*rotate 180* */
                                                          : UIImageOrientationUp /*do not rotate*/;
  } else if (isNearValue(90.0, yxAtan)) {
    return UIImageOrientationLeft;
  }
  // If none of the above, then the device is likely facing straight down or straight up -- just
  // pick something arbitrary
  // TODO: Maybe use the UIInterfaceOrientation if in these scenarios
  return UIImageOrientationUp;
}

@end
