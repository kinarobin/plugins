//
//  FLTImageStreamHandler.h
//  camera
//
//  Created by libin14 on 2020/9/2.
//

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLTImageStreamHandler : NSObject <FlutterStreamHandler>
@property FlutterEventSink eventSink;
@end

NS_ASSUME_NONNULL_END
