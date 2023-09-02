#import <React/RCTConvert.h>
#import <Foundation/Foundation.h>
#import "../View/dto/ArrowDTO.h"
#import "../View/dto/GradientDTO.h"
@import YandexMapsMobile;

@interface RCTConvert(Yamap)

@end

@implementation RCTConvert(Yamap)

+ (YMKPoint*)YMKPoint:(id)json {
    json = [self NSDictionary:json];
    YMKPoint *target = [YMKPoint pointWithLatitude:[self double:json[@"lat"]] longitude:[self double:json[@"lon"]]];

    return target;
}

+ (YMKScreenPoint*)YMKScreenPoint:(id)json {
    json = [self NSDictionary:json];
    YMKScreenPoint *target = [YMKScreenPoint screenPointWithX:[self float:json[@"x"]] y:[self float:json[@"y"]]];

    return target;
}

+ (NSArray*)Vehicles:(id)json {
    return [self NSArray:json];
}

+ (NSMutableArray<YMKPoint*>*)Points:(id)json {
    NSArray* parsedArray = [self NSArray:json];
    NSMutableArray* result = [[NSMutableArray alloc] init];

    for (NSDictionary* jsonMarker in parsedArray) {
        double lat = [[jsonMarker valueForKey:@"lat"] doubleValue];
        double lon = [[jsonMarker valueForKey:@"lon"] doubleValue];
        YMKPoint *point = [YMKPoint pointWithLatitude:lat longitude:lon];
        [result addObject:point];
    }

    return result;
}

+ (NSMutableArray<YMKSubpolyline*>*)HideSegments:(id)json {
    NSArray* parsedArray = [self NSArray:json];
    NSMutableArray<YMKSubpolyline*> *result = [[NSMutableArray alloc] init];

    for (NSDictionary* jsonMarker in parsedArray) {
        YMKPolylinePosition *begin = [self createPolylinePosition:[jsonMarker objectForKey:@"begin"]];
        YMKPolylinePosition *end = [self createPolylinePosition:[jsonMarker objectForKey:@"end"]];

        [result addObject:[YMKSubpolyline subpolylineWithBegin:begin end:end]];
    }

    return result;
}

+ (YMKPolylinePosition*)createPolylinePosition:(NSDictionary*)positionMap {
    NSUInteger segmentIndex = [[positionMap valueForKey:@"segmentIndex"] unsignedIntegerValue];
    double segmentPosition = [[positionMap valueForKey:@"segmentPosition"] doubleValue];

    return [YMKPolylinePosition polylinePositionWithSegmentIndex:segmentIndex segmentPosition:segmentPosition];
}


+ (ArrowDTO*)ArrowDTO:(id)json {
    json = [self NSDictionary:json];

    UIColor *arrowOutlineColor = [RCTConvert UIColor:json[@"arrowOutlineColor"]];
    float arrowOutlineWidth = [self float:json[@"arrowOutlineWidth"]];
    float length = [self float:json[@"length"]];
    UIColor *arrowColor = [RCTConvert UIColor:json[@"arrowColor"]];

    NSArray* parsedArray = [self NSArray:json[@"positions"]];
    NSMutableArray<YMKPolylinePosition *>* positions = [[NSMutableArray alloc] init];

    for (NSDictionary* jsonMarker in parsedArray) {
        [positions addObject:[self createPolylinePosition:jsonMarker]];
    }

    ArrowDTO *arrow = [[ArrowDTO alloc] initWithArrowOutlineColor:arrowOutlineColor arrowOutlineWidth:arrowOutlineWidth length:length arrowColor:arrowColor positions:positions];

    return arrow;
}

+ (GradientDTO*)GradientDTO:(id)json {
    json = [self NSDictionary:json];

    float length = [self float:json[@"length"]];

    NSArray* parsedArray = [self NSArray:json[@"colors"]];
    NSMutableArray<UIColor *>* colors = [[NSMutableArray alloc] init];

    for (NSDictionary* jsonMarker in parsedArray) {
        [colors addObject:[RCTConvert UIColor:jsonMarker]];
    }

    GradientDTO *gradientDTO = [[GradientDTO alloc] initWithLength:length colors:colors];

    return gradientDTO;
}

+ (NSMutableArray<YMKScreenPoint*>*)ScreenPoints:(id)json {
    NSArray* parsedArray = [self NSArray:json];
    NSMutableArray* result = [[NSMutableArray alloc] init];

    for (NSDictionary* jsonMarker in parsedArray) {
        float x = [[jsonMarker valueForKey:@"x"] floatValue];
        float y = [[jsonMarker valueForKey:@"y"] floatValue];
        YMKScreenPoint *point = [YMKScreenPoint screenPointWithX:x y:y];
        [result addObject:point];
    }

    return result;
}

+ (float)Zoom:(id)json {
    json = [self NSDictionary:json];
    return [self float:json[@"zoom"]];
}

+ (float)Azimuth:(id)json {
    json = [self NSDictionary:json];
    return [self float:json[@"azimuth"]];
}

+ (float)Tilt:(id)json {
    json = [self NSDictionary:json];
    return [self float:json[@"tilt"]];
}

@end
