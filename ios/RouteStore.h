#import <Foundation/Foundation.h>
@import YandexMapsMobile;

@interface RouteStore : NSObject

@property (nonatomic, strong) NSMutableArray *routeDictionary;
@property (nonatomic, strong) YMKPolyline *savedPolyline;

+ (instancetype)sharedInstance;
- (void)addElement:(YMKDrivingRoute *)route;
- (YMKDrivingRoute *)accessRouteForKey:(NSString *)key;
- (void)clear;
- (YMKPolyline *)getPolyline;
- (void)setPolyline:(YMKPolyline *)polyline;
- (YMKPolyline *)accessRoutePolylineForKey:(NSString *)key;

@end
