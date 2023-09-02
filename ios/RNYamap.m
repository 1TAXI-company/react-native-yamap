#import "RNYamap.h"
@import YandexMapsMobile;
#import "RouteStore.h"

@implementation yamap

static NSString * _pinIcon;
static NSString * _arrowIcon;
static NSString * _markerIcon;
static NSString * _selectedMarkerIcon;

@synthesize map;

- (instancetype) init {
    self = [super init];
    if (self) {
        map = [[YamapView alloc] init];
    }

    return self;
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (void)initWithKey:(NSString *) apiKey {
    [YMKMapKit setApiKey: apiKey];
    [[YMKMapKit sharedInstance] onStart];
}

- (dispatch_queue_t)methodQueue{
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(init: (NSString *) apiKey
          resolver:(RCTPromiseResolveBlock)resolve
          rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        [self initWithKey: apiKey];
        resolve(nil);
    } @catch (NSException *exception) {
        NSError *error = nil;
        if (exception.userInfo.count > 0) {
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:exception.userInfo];
        }
        reject(exception.name, exception.reason ?: @"Error initiating YMKMapKit", error);
    }
}

RCT_EXPORT_METHOD(setLocale: (NSString *) locale successCallback:(RCTResponseSenderBlock)successCb errorCallback:(RCTResponseSenderBlock) errorCb) {
    [YRTI18nManagerFactory setLocaleWithLocale:locale];
    successCb(@[]);
}

RCT_EXPORT_METHOD(resetLocale:(RCTResponseSenderBlock)successCb errorCallback:(RCTResponseSenderBlock) errorCb) {
    [YRTI18nManagerFactory setLocaleWithLocale:nil];
    successCb(@[]);
}

RCT_EXPORT_METHOD(getLocale:(RCTResponseSenderBlock)successCb errorCallback:(RCTResponseSenderBlock) errorCb) {
    NSString * locale = [YRTI18nManagerFactory getLocale];
    successCb(@[locale]);
}

RCT_EXPORT_METHOD(getRoutePositionInfo:(nonnull NSString *)routeId resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject) {
    YMKDrivingRoute *route = [[RouteStore sharedInstance] accessRouteForKey:routeId];

    if (route != nil) {
        YMKRoutePosition *routePosition = [route routePosition];

        NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
        [json setValue:@([routePosition distanceToFinish]) forKey:@"distanceToFinish"];
        [json setValue:@([routePosition timeToFinish]) forKey:@"timeToFinish"];
        [json setValue:@([routePosition heading]) forKey:@"heading"];

        YMKPoint *point = [routePosition point];
        NSMutableDictionary *pointJson = [[NSMutableDictionary alloc] init];
        [pointJson setValue:[NSNumber numberWithDouble:point.latitude] forKey:@"lat"];
        [pointJson setValue:[NSNumber numberWithDouble:point.longitude] forKey:@"lon"];

        [json setValue:pointJson forKey:@"point"];

        resolve(json);
    } else {
        reject(@"ERROR", @"noRouteWithSuchId", nil);
    }
}

RCT_EXPORT_METHOD(getReachedPosition:(nonnull NSString *)routeId resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject) {
    YMKDrivingRoute *route = [[RouteStore sharedInstance] accessRouteForKey:routeId];

    if (route != nil) {
        YMKPolylinePosition *polyline = [route position];

        NSMutableDictionary *polylineJson = [[NSMutableDictionary alloc] init];
        [polylineJson setValue:[NSNumber numberWithDouble:polyline.segmentIndex] forKey:@"segmentIndex"];
        [polylineJson setValue:[NSNumber numberWithDouble:polyline.segmentPosition] forKey:@"segmentPosition"];

        resolve(polylineJson);
    } else {
        reject(@"ERROR", @"noRouteWithSuchId", nil);
    }
}

RCT_EXPORT_METHOD(isInRoute:(nonnull NSString *)routeId checkableRouteId:(nonnull NSString *)checkableRouteId resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject) {
    YMKDrivingRoute *route = [[RouteStore sharedInstance] accessRouteForKey:routeId];

    if (route != nil) {
        YMKRoutePosition *routePosition = [route routePosition];

        NSMutableDictionary *json = [[NSMutableDictionary alloc] init];

        [json setValue:@([routePosition onRouteWithRouteId:checkableRouteId]) forKey:@"onRoute"];

        resolve(json);
    } else {
        reject(@"ERROR", @"noRouteWithSuchId", nil);
    }
}

RCT_EXPORT_METHOD(getDistance:(id)json resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject) {
    NSString *routeId = json[@"routeId"];

    YMKDrivingRoute *route = [[RouteStore sharedInstance] accessRouteForKey:routeId];

    if (route != nil) {
        YMKPolylinePosition *position2 = [self createPolylinePosition:json[@"position2"]];

        YMKPolylinePosition *position1 = nil;

        if (json[@"position1"] != nil) {
            position1 = [self createPolylinePosition:json[@"position1"]];
        } else {
            position1 = [route position];
        }

        float distance = [YMKPolylineUtils distanceBetweenPolylinePositionsWithPolyline:[route geometry] from:position1 to:position2];
        resolve(@(distance));
    } else {
        reject(@"ERROR", @"noRouteWithSuchId", nil);
    }
}

- (YMKPolylinePosition*)createPolylinePosition:(NSDictionary*)positionMap {
    NSUInteger segmentIndex = [[positionMap valueForKey:@"segmentIndex"] unsignedIntegerValue];
    double segmentPosition = [[positionMap valueForKey:@"segmentPosition"] doubleValue];

    return [YMKPolylinePosition polylinePositionWithSegmentIndex:segmentIndex segmentPosition:segmentPosition];
}

RCT_EXPORT_MODULE()

@end
