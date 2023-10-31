#import <Foundation/Foundation.h>
@import YandexMapsMobile;

@interface RouteStore : NSObject

@property (nonatomic, strong) NSMutableArray *routeDictionary;

+ (instancetype)sharedInstance;
- (void)addElement:(YMKDrivingRoute *)route;
- (YMKDrivingRoute *)accessRouteForKey:(NSString *)key;
- (void)clear;

@end
