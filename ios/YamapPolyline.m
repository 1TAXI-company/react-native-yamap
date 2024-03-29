#import <React/RCTViewManager.h>
#import <MapKit/MapKit.h>
#import <math.h>
#import "YamapPolyline.h"
#import "RNYamap.h"
#import "View/dto/ArrowDTO.h"
#import "View/dto/GradientDTO.h"
#import "RouteStore.h"

#import "View/YamapPolylineView.h"
#import "View/RNYMView.h"

#import "Converter/RCTConvert+Yamap.m"

#ifndef MAX
#import <NSObjCRuntime.h>
#endif

@implementation YamapPolyline

RCT_EXPORT_MODULE()

- (NSArray<NSString*>*)supportedEvents {
    return @[@"onPress"];
}

- (instancetype)init {
    self = [super init];

    return self;
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (UIView *_Nullable)view {
    return [[YamapPolylineView alloc] init];
}

// PROPS
RCT_EXPORT_VIEW_PROPERTY(onPress, RCTBubblingEventBlock)

RCT_CUSTOM_VIEW_PROPERTY (points, NSArray<YMKPoint>, YamapPolylineView) {
    if (json != nil) {
        [view setPolylinePoints: [RCTConvert Points:json]];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(outlineColor, NSNumber, YamapPolylineView) {
    [view setOutlineColor: [RCTConvert UIColor:json]];
}

RCT_CUSTOM_VIEW_PROPERTY(strokeColor, NSNumber, YamapPolylineView) {
    [view setStrokeColor: [RCTConvert UIColor:json]];
}

RCT_CUSTOM_VIEW_PROPERTY(strokeWidth, NSNumber, YamapPolylineView) {
    [view setStrokeWidth: json];
}

RCT_CUSTOM_VIEW_PROPERTY(dashLength, NSNumber, YamapPolylineView) {
    [view setDashLength: json];
}

RCT_CUSTOM_VIEW_PROPERTY(gapLength, NSNumber, YamapPolylineView) {
    [view setGapLength: json];
}

RCT_CUSTOM_VIEW_PROPERTY(dashOffset, NSNumber, YamapPolylineView) {
    [view setDashOffset: json];
}

RCT_CUSTOM_VIEW_PROPERTY(outlineWidth, NSNumber, YamapPolylineView) {
    [view setOutlineWidth: json];
}

RCT_CUSTOM_VIEW_PROPERTY(zIndex, NSNumber, YamapPolylineView) {
    [view setZIndex: json];
}

RCT_CUSTOM_VIEW_PROPERTY(turnRadius, NSNumber, YamapPolylineView) {
    [view setTurnRadius: json];
}

RCT_CUSTOM_VIEW_PROPERTY(arrow, ArrowDTO, YamapPolylineView) {
    [view setArrowDTO:[RCTConvert ArrowDTO:json]];
}

RCT_CUSTOM_VIEW_PROPERTY(gradientInfo, GradientDTO, YamapPolylineView) {
    [view setGradientDTO:[RCTConvert GradientDTO:json]];
}

RCT_CUSTOM_VIEW_PROPERTY(hide, NSArray<YMKSubpolyline>, YamapPolylineView) {
    [view setHideSegments:[RCTConvert HideSegments:json]];
}

RCT_CUSTOM_VIEW_PROPERTY(save, BOOL, YamapPolylineView) {
    if ([json boolValue]) {
        RouteStore *routeStore = [RouteStore sharedInstance];
        [routeStore setPolyline:[view getPolyline]];
    }
}

@end
