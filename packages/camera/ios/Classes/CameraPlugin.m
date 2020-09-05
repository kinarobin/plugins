// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "CameraPlugin.h"
#import "FLTSavePhotoDelegate.h"
#import "FLTImageStreamHandler.h"
#import "FLTCam.h"

// Mirrors ResolutionPreset in camera.dart

@interface CameraPlugin ()
@property(readonly, nonatomic) NSObject<FlutterTextureRegistry> *registry;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger> *messenger;
@property(readonly, nonatomic) FLTCam *camera;
@end

@implementation CameraPlugin {
  dispatch_queue_t _dispatchQueue;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/camera"
                                  binaryMessenger:[registrar messenger]];
  CameraPlugin *instance = [[CameraPlugin alloc] initWithRegistry:[registrar textures]
                                                        messenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistry:(NSObject<FlutterTextureRegistry> *)registry
                       messenger:(NSObject<FlutterBinaryMessenger> *)messenger {
  self = [super init];
  NSAssert(self, @"super init cannot be nil");
  _registry = registry;
  _messenger = messenger;
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if (_dispatchQueue == nil) {
    _dispatchQueue = dispatch_queue_create("io.flutter.camera.dispatchqueue", NULL);
  }

  // Invoke the plugin on another dispatch queue to avoid blocking the UI.
  dispatch_async(_dispatchQueue, ^{
    [self handleMethodCallAsync:call result:result];
  });
}

- (void)handleMethodCallAsync:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"availableCameras" isEqualToString:call.method]) {
    if (@available(iOS 10.0, *)) {
      AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
          discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                mediaType:AVMediaTypeVideo
                                 position:AVCaptureDevicePositionUnspecified];
      NSArray<AVCaptureDevice *> *devices = discoverySession.devices;
      NSMutableArray<NSDictionary<NSString *, NSObject *> *> *reply =
          [[NSMutableArray alloc] initWithCapacity:devices.count];
      for (AVCaptureDevice *device in devices) {
        NSString *lensFacing;
        switch ([device position]) {
          case AVCaptureDevicePositionBack:
            lensFacing = @"back";
            break;
          case AVCaptureDevicePositionFront:
            lensFacing = @"front";
            break;
          case AVCaptureDevicePositionUnspecified:
            lensFacing = @"external";
            break;
        }
        [reply addObject:@{
          @"name" : [device uniqueID],
          @"lensFacing" : lensFacing,
          @"sensorOrientation" : @90,
        }];
      }
      result(reply);
    } else {
      result(FlutterMethodNotImplemented);
    }
  } else if ([@"initialize" isEqualToString:call.method]) {
    NSString *cameraName = call.arguments[@"cameraName"];
    NSString *resolutionPreset = call.arguments[@"resolutionPreset"];
    NSNumber *enableAudio = call.arguments[@"enableAudio"];
    NSError *error;
    FLTCam *cam = [[FLTCam alloc] initWithCameraName:cameraName
                                    resolutionPreset:resolutionPreset
                                         enableAudio:[enableAudio boolValue]
                                       dispatchQueue:_dispatchQueue
                                               error:&error];
    if (error) {
      result(getFlutterError(error));
    } else {
      if (_camera) {
        [_camera close];
      }
      int64_t textureId = [_registry registerTexture:cam];
      _camera = cam;
      __weak CameraPlugin *weakSelf = self;
      cam.onFrameAvailable = ^{
        [weakSelf.registry textureFrameAvailable:textureId];
      };
      FlutterEventChannel *eventChannel =
          [FlutterEventChannel eventChannelWithName:[NSString stringWithFormat:@"flutter.io/cameraPlugin/cameraEvents%lld", textureId]
                                    binaryMessenger:_messenger];
      [eventChannel setStreamHandler:cam];
      cam.eventChannel = eventChannel;
      result(@{
        @"textureId" : @(textureId),
        @"previewWidth" : @(cam.previewSize.width),
        @"previewHeight" : @(cam.previewSize.height),
        @"captureWidth" : @(cam.captureSize.width),
        @"captureHeight" : @(cam.captureSize.height),
      });
      [cam start];
    }
  } else if ([@"startImageStream" isEqualToString:call.method]) {
    [_camera startImageStreamWithMessenger:_messenger];
    result(nil);
  } else if ([@"stopImageStream" isEqualToString:call.method]) {
    [_camera stopImageStream];
    result(nil);
  } else if ([@"pauseVideoRecording" isEqualToString:call.method]) {
    [_camera pauseVideoRecording];
    result(nil);
  } else if ([@"resumeVideoRecording" isEqualToString:call.method]) {
    [_camera resumeVideoRecording];
    result(nil);
  } else {
    NSDictionary *argsMap = call.arguments;
    NSUInteger textureId = ((NSNumber *)argsMap[@"textureId"]).unsignedIntegerValue;
    if ([@"takePicture" isEqualToString:call.method]) {
      if (@available(iOS 10.0, *)) {
        [_camera captureToFile:call.arguments[@"path"] result:result];
      } else {
        result(FlutterMethodNotImplemented);
      }
    } else if ([@"dispose" isEqualToString:call.method]) {
      [_registry unregisterTexture:textureId];
      [_camera close];
      _dispatchQueue = nil;
      result(nil);
    } else if ([@"prepareForVideoRecording" isEqualToString:call.method]) {
      [_camera setUpCaptureSessionForAudio];
      result(nil);
    } else if ([@"startVideoRecording" isEqualToString:call.method]) {
      [_camera startVideoRecordingAtPath:call.arguments[@"filePath"] result:result];
    } else if ([@"stopVideoRecording" isEqualToString:call.method]) {
      [_camera stopVideoRecordingWithResult:result];
    } else {
      result(FlutterMethodNotImplemented);
    }
  }
}

@end
