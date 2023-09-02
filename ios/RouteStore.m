#import "RouteStore.h"

@implementation RouteStore

+ (instancetype)sharedInstance {
    static RouteStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RouteStore alloc] init];
        sharedInstance.routeDictionary = [NSMutableDictionary dictionary];
    });
    return sharedInstance;
}

- (void)addElement:(YMKDrivingRoute *)route forKey:(NSString *)key {
    if (route && key) {
        self.routeDictionary[key] = route;
    }
}

- (YMKDrivingRoute *)accessRouteForKey:(NSString *)key {
    return self.routeDictionary[key];
}

- (void)clear {
    [self.routeDictionary removeAllObjects];
}

@end

