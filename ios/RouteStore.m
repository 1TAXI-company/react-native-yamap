#import "RouteStore.h"

@implementation RouteStore

+ (instancetype)sharedInstance {
    static RouteStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RouteStore alloc] init];
        sharedInstance.routeDictionary = [NSMutableArray array];
    });
    return sharedInstance;
}

- (void)addElement:(YMKDrivingRoute *)route {
    if (route) {
        [self.routeDictionary addObject:route];
    }
}

- (YMKDrivingRoute *)accessRouteForKey:(NSString *)key {
    for (YMKDrivingRoute *route in self.routeDictionary) {
        if ([[route routeId] isEqualToString:key]) {
            return route;
        }
    }
    return nil;
}

- (YMKPolyline *)accessRoutePolylineForKey:(NSString *)key {
    for (YMKDrivingRoute *route in self.routeDictionary) {
        if ([[route routeId] isEqualToString:key]) {
            return [route geometry];
        }
    }
    return nil;
}

- (YMKPolyline *)getPolyline {
    return _savedPolyline;
}

- (void)setPolyline:(YMKPolyline *)polyline {
    if (polyline) {
        _savedPolyline = polyline;
    }
}

- (void)clear {
    if (self.routeDictionary.count > 10) {
        NSUInteger elementsToRemove = self.routeDictionary.count - 10; // Calculate the number of elements to remove from the beginning
        NSRange range = NSMakeRange(0, elementsToRemove); // Create a range to remove elements from the beginning
        [self.routeDictionary removeObjectsInRange:range]; // Remove elements from the beginning of the array
    }
}

@end

