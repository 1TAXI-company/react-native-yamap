#import <Foundation/Foundation.h>
@import YandexMapsMobile;

@interface RouteStore : NSObject

@property (nonatomic, strong) NSMutableDictionary *routeDictionary;

+ (instancetype)sharedInstance;
- (void)addElement:(YMKDrivingRoute *)route forKey:(NSString *)key;
- (YMKDrivingRoute *)accessRouteForKey:(NSString *)key;
- (void)clear;

@end
