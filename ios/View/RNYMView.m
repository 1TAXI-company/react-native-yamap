#import <React/RCTComponent.h>
#import <React/UIView+React.h>

#if TARGET_OS_SIMULATOR
#import <mach-o/arch.h>
#endif

#import <MapKit/MapKit.h>
#import "../Converter/RCTConvert+Yamap.m"
#import "../RouteStore.h"
@import YandexMapsMobile;

#ifndef MAX
#import <NSObjCRuntime.h>
#endif

#import "YamapPolygonView.h"
#import "YamapPolylineView.h"
#import "YamapMarkerView.h"
#import "YamapCircleView.h"
#import "RNYMView.h"

#define ANDROID_COLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 green:((c>>8)&0xFF)/255.0 blue:((c)&0xFF)/255.0  alpha:((c>>24)&0xFF)/255.0]

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation RNYMView {
    YMKMasstransitSession *masstransitSession;
    YMKMasstransitSession *walkSession;
    YMKMasstransitRouter *masstransitRouter;
    YMKDrivingRouter *drivingRouter;
    YMKDrivingSession *drivingSession;
    YMKPedestrianRouter *pedestrianRouter;
    YMKTransitOptions *transitOptions;
    YMKMasstransitSessionRouteHandler routeHandler;
    NSMutableArray<UIView*> *_reactSubviews;
    NSMutableArray *routes;
    NSMutableArray *currentRouteInfo;
    NSMutableArray<YMKRequestPoint *> *lastKnownRoutePoints;
    YMKUserLocationView *userLocationView;
    NSMutableDictionary *vehicleColors;
    UIImage *userLocationImage;
    NSNumber *userLocationImageScale;
    NSArray *acceptVehicleTypes;
    YMKUserLocationLayer *userLayer;
    YMKTrafficLayer *trafficLayer;
    UIColor *userLocationAccuracyFillColor;
    UIColor *userLocationAccuracyStrokeColor;
    float userLocationAccuracyStrokeWidth;
}

- (instancetype)init {
#if TARGET_OS_SIMULATOR
    NXArchInfo *archInfo = NXGetLocalArchInfo();
    NSString *cpuArch = [NSString stringWithUTF8String:archInfo->description];
    self = [super initWithFrame:CGRectZero vulkanPreferred:[cpuArch hasPrefix:@"ARM64"]];
#else
    self = [super initWithFrame:CGRectZero];
#endif

    _reactSubviews = [[NSMutableArray alloc] init];
    masstransitRouter = [[YMKTransport sharedInstance] createMasstransitRouter];
    drivingRouter = [[YMKDirections sharedInstance] createDrivingRouter];
    pedestrianRouter = [[YMKTransport sharedInstance] createPedestrianRouter];
    transitOptions = [YMKTransitOptions transitOptionsWithAvoid:YMKFilterVehicleTypesNone timeOptions:[[YMKTimeOptions alloc] init]];    acceptVehicleTypes = [[NSMutableArray<NSString *> alloc] init];
    routes = [[NSMutableArray alloc] init];
    currentRouteInfo = [[NSMutableArray alloc] init];
    lastKnownRoutePoints = [[NSMutableArray alloc] init];
    vehicleColors = [[NSMutableDictionary alloc] init];
    [vehicleColors setObject:@"#59ACFF" forKey:@"bus"];
    [vehicleColors setObject:@"#7D60BD" forKey:@"minibus"];
    [vehicleColors setObject:@"#F8634F" forKey:@"railway"];
    [vehicleColors setObject:@"#C86DD7" forKey:@"tramway"];
    [vehicleColors setObject:@"#3023AE" forKey:@"suburban"];
    [vehicleColors setObject:@"#BDCCDC" forKey:@"underground"];
    [vehicleColors setObject:@"#55CfDC" forKey:@"trolleybus"];
    [vehicleColors setObject:@"#2d9da8" forKey:@"walk"];
    userLocationImageScale = [NSNumber numberWithFloat:1.f];
    userLocationAccuracyFillColor = nil;
    userLocationAccuracyStrokeColor = nil;
    userLocationAccuracyStrokeWidth = 0.f;
    [self.mapWindow.map addCameraListenerWithCameraListener:self];
    [self.mapWindow.map addInputListenerWithInputListener:(id<YMKMapInputListener>) self];
    [self.mapWindow.map setMapLoadedListenerWithMapLoadedListener:self];
    return self;
}

- (NSDictionary*)convertDrivingRouteSection:(YMKDrivingRoute*)route withSection:(YMKDrivingSection*)section withRouteIndex:(int)routeIndex {
    NSMutableDictionary *sectionJson = [[NSMutableDictionary alloc] init];

    [sectionJson setObject:@(routeIndex) forKey:@"routeIndex"];

    [self populateSectionMetadata:section json:sectionJson];

    YMKSubpolyline* geometry = section.geometry;

    if (geometry != nil) {
        [sectionJson setObject:@(geometry.begin.segmentIndex) forKey:@"beginPointIndex"];
        [sectionJson setObject:@(geometry.end.segmentIndex) forKey:@"endPointIndex"];
    }

    NSMutableArray* points = [[NSMutableArray alloc] init];
    YMKPolyline* subpolyline = YMKMakeSubpolyline(route.geometry, section.geometry);

    for (int i = 0; i < [subpolyline.points count]; ++i) {
        YMKPoint* point = [subpolyline.points objectAtIndex:i];
        NSMutableDictionary* jsonPoint = [[NSMutableDictionary alloc] init];
        [jsonPoint setValue:[NSNumber numberWithDouble:point.latitude] forKey:@"lat"];
        [jsonPoint setValue:[NSNumber numberWithDouble:point.longitude] forKey:@"lon"];
        [points addObject:jsonPoint];
    }
    [sectionJson setValue:points forKey:@"points"];

    return sectionJson;
}

- (NSDictionary *)convertRouteSection:(YMKMasstransitRoute *)route withSection:(YMKMasstransitSection *)section {
    int routeIndex = 0;
    YMKMasstransitWeight* routeWeight = route.metadata.weight;
    YMKMasstransitSectionMetadataSectionData *data = section.metadata.data;
    NSMutableDictionary *routeMetadata = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *routeWeightData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *sectionWeightData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *transports = [[NSMutableDictionary alloc] init];
    NSMutableArray *stops = [[NSMutableArray alloc] init];
    [routeWeightData setObject:routeWeight.time.text forKey:@"time"];
    [routeWeightData setObject:@(routeWeight.transfersCount) forKey:@"transferCount"];
    [routeWeightData setObject:@(routeWeight.walkingDistance.value) forKey:@"walkingDistance"];
    [sectionWeightData setObject:section.metadata.weight.time.text forKey:@"time"];
    [sectionWeightData setObject:@(section.metadata.weight.transfersCount) forKey:@"transferCount"];
    [sectionWeightData setObject:@(section.metadata.weight.walkingDistance.value) forKey:@"walkingDistance"];
    [routeMetadata setObject:sectionWeightData forKey:@"sectionInfo"];
    [routeMetadata setObject:routeWeightData forKey:@"routeInfo"];
    [routeMetadata setObject:@(routeIndex) forKey:@"routeIndex"];

    for (YMKMasstransitRouteStop *stop in section.stops) {
        [stops addObject:stop.metadata.stop.name];
    }

    [routeMetadata setObject:stops forKey:@"stops"];

    if (data.transports != nil) {
        for (YMKMasstransitTransport *transport in data.transports) {
            for (NSString *type in transport.line.vehicleTypes) {
                if ([type isEqual: @"suburban"]) continue;
                if (transports[type] != nil) {
                    NSMutableArray *list = transports[type];
                    if (list != nil) {
                        [list addObject:transport.line.name];
                        [transports setObject:list forKey:type];
                    }
                } else {
                    NSMutableArray *list = [[NSMutableArray alloc] init];
                    [list addObject:transport.line.name];
                    [transports setObject:list forKey:type];
                }
                [routeMetadata setObject:type forKey:@"type"];
                UIColor *color;
                if (transport.line.style != nil) {
                    color = UIColorFromRGB([transport.line.style.color integerValue]);
                } else {
                    if ([vehicleColors valueForKey:type] != nil) {
                        color = [RNYMView colorFromHexString:vehicleColors[type]];
                    } else {
                        color = UIColor.blackColor;
                    }
                }
                [routeMetadata setObject:[RNYMView hexStringFromColor:color] forKey:@"sectionColor"];
            }
        }
    } else {
        [routeMetadata setObject:UIColor.darkGrayColor forKey:@"sectionColor"];
        if (section.metadata.weight.walkingDistance.value == 0) {
            [routeMetadata setObject:@"waiting" forKey:@"type"];
        } else {
            [routeMetadata setObject:@"walk" forKey:@"type"];
        }
    }

    NSMutableDictionary *wTransports = [[NSMutableDictionary alloc] init];

    for (NSString *key in transports) {
        [wTransports setObject:[transports valueForKey:key] forKey:key];
    }

    [routeMetadata setObject:wTransports forKey:@"transports"];
    NSMutableArray *points = [[NSMutableArray alloc] init];
    YMKPolyline *subpolyline = YMKMakeSubpolyline(route.geometry, section.geometry);

    for (int i = 0; i < [subpolyline.points count]; ++i) {
        YMKPoint *point = [subpolyline.points objectAtIndex:i];
        NSMutableDictionary *jsonPoint = [[NSMutableDictionary alloc] init];
        [jsonPoint setValue:[NSNumber numberWithDouble:point.latitude] forKey:@"lat"];
        [jsonPoint setValue:[NSNumber numberWithDouble:point.longitude] forKey:@"lon"];
        [points addObject:jsonPoint];
    }

    [routeMetadata setValue:points forKey:@"points"];

    return routeMetadata;
}

- (NSString *)convertJamTypeToString:(YMKDrivingJamType)jamType {
    NSString *jamTypeString = nil;

    switch (jamType) {
        case YMKDrivingJamTypeUnknown:
            jamTypeString = @"UNKNOWN";
            break;
        case YMKDrivingJamTypeFree:
            jamTypeString = @"FREE";
            break;
        case YMKDrivingJamTypeHard:
            jamTypeString = @"HARD";
            break;
        case YMKDrivingJamTypeVeryHard:
            jamTypeString = @"VERY_HARD";
            break;
        case YMKDrivingJamTypeLight:
            jamTypeString = @"LIGHT";
            break;
        case YMKDrivingJamTypeBlocked:
            jamTypeString = @"BLOCKED";
            break;
        default:
            jamTypeString = @"UNKNOWN";
            break;
    }

    return jamTypeString;
}

- (void)findRoutes:(NSArray<YMKRequestPoint *> *)_points vehicles:(NSArray<NSString *> *)vehicles withId:(NSString *)_id needNavigationInfo:(BOOL)needNavigationInfo {
    __weak RNYMView *weakSelf = self;

    if ([vehicles count] == 1 && [[vehicles objectAtIndex:0] isEqualToString:@"car"]) {
        YMKDrivingDrivingOptions *drivingOptions = [[YMKDrivingDrivingOptions alloc] init];
        YMKDrivingVehicleOptions *vehicleOptions = [[YMKDrivingVehicleOptions alloc] init];

        drivingSession = [drivingRouter requestRoutesWithPoints:_points drivingOptions:drivingOptions
                                                 vehicleOptions:vehicleOptions routeHandler:^(NSArray<YMKDrivingRoute *> *routes, NSError *error) {
            RNYMView *strongSelf = weakSelf;

            if (error != nil) {
                [strongSelf onReceiveNativeEvent: @{@"id": _id, @"status": @"error"}];
                return;
            }

            [[RouteStore sharedInstance] clear];

            NSMutableDictionary* response = [[NSMutableDictionary alloc] init];
            [response setValue:_id forKey:@"id"];
            [response setValue:@"success" forKey:@"status"];
            NSMutableArray* jsonRoutes = [[NSMutableArray alloc] init];

            for (int i = 0; i < [routes count]; ++i) {
                YMKDrivingRoute *_route = [routes objectAtIndex:i];

                NSString *routeId = _route.routeId != nil && _route.routeId.length > 0 ? _route.routeId : [NSString stringWithFormat:@"%d", i];
                [[RouteStore sharedInstance] addElement:_route forKey:routeId];
                NSMutableDictionary *jsonRoute = [[NSMutableDictionary alloc] init];
                [jsonRoute setValue:routeId forKey:@"id"];

                [self populateMandatoryInfo:_route json: jsonRoute];

                if (needNavigationInfo) {
                    [self populateDrivingInfo:_route json: jsonRoute routeIndex:i];
                }

                [jsonRoutes addObject:jsonRoute];
            }

            [response setValue:jsonRoutes forKey:@"routes"];
            [strongSelf onReceiveNativeEvent: response];
        }];

        return;
    }

    YMKMasstransitSessionRouteHandler _routeHandler = ^(NSArray<YMKMasstransitRoute *> *routes, NSError *error) {
        RNYMView *strongSelf = weakSelf;
        if (error != nil) {
            [strongSelf onReceiveNativeEvent: @{@"id": _id, @"status": @"error"}];
            return;
        }
        NSMutableDictionary* response = [[NSMutableDictionary alloc] init];
        [response setValue:_id forKey:@"id"];
        [response setValue:@"success" forKey:@"status"];
        NSMutableArray *jsonRoutes = [[NSMutableArray alloc] init];
        for (int i = 0; i < [routes count]; ++i) {
            YMKMasstransitRoute *_route = [routes objectAtIndex:i];
            NSMutableDictionary *jsonRoute = [[NSMutableDictionary alloc] init];

            [jsonRoute setValue:[NSString stringWithFormat:@"%d", i] forKey:@"id"];
            NSMutableArray *sections = [[NSMutableArray alloc] init];
            NSArray<YMKMasstransitSection *> *_sections = [_route sections];
            for (int j = 0; j < [_sections count]; ++j) {
                NSDictionary *jsonSection = [self convertRouteSection:_route withSection: [_sections objectAtIndex:j]];
                [sections addObject:jsonSection];
            }
            [jsonRoute setValue:sections forKey:@"sections"];
            [jsonRoutes addObject:jsonRoute];
        }
        [response setValue:jsonRoutes forKey:@"routes"];
        [strongSelf onReceiveNativeEvent: response];
    };

    if ([vehicles count] == 0) {
        walkSession = [pedestrianRouter requestRoutesWithPoints:_points timeOptions:[[YMKTimeOptions alloc] init] routeHandler:_routeHandler];
        return;
    }

    YMKTransitOptions *_transitOptions = [YMKTransitOptions transitOptionsWithAvoid:YMKFilterVehicleTypesNone timeOptions:[[YMKTimeOptions alloc] init]];
    masstransitSession = [masstransitRouter requestRoutesWithPoints:_points transitOptions:_transitOptions routeHandler:_routeHandler];
}

- (void)populateMandatoryInfo:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSMutableArray *jamsArray = [[NSMutableArray alloc] init];
    NSArray<YMKDrivingJamSegment *> *jamSegments = [route jamSegments];
    for (YMKDrivingJamSegment *jamSegment in jamSegments) {
        NSString *jamTypeString = [self convertJamTypeToString:jamSegment.jamType];
        [jamsArray addObject:jamTypeString];
    }
    [jsonRoute setValue:jamsArray forKey:@"jams"];

    NSMutableArray *geometryArray = [[NSMutableArray alloc] init];
    NSArray<YMKPoint *> *geometries = [[route geometry] points];
    for (YMKPoint *point in geometries) {
        [geometryArray addObject:[self createMapFromPoint:point]];
    }
    [jsonRoute setObject:geometryArray forKey:@"geometry"];

    [self populateRouteMetadataInfo:route json:jsonRoute];
}

- (void)populateRouteMetadataInfo:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    YMKDrivingWeight *routeWeight = route.metadata.weight;
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata setObject:routeWeight.time.text forKey:@"time"];
    [metadata setObject:routeWeight.timeWithTraffic.text forKey:@"timeWithTraffic"];
    [metadata setObject:@(routeWeight.distance.value) forKey:@"distance"];

    YMKDrivingFlags *flags = route.metadata.flags;
    if (flags != nil) {
        NSMutableDictionary *flagsMap = [[NSMutableDictionary alloc] init];
        [flagsMap setValue:[NSNumber numberWithBool:flags.hasTolls] forKey:@"time"];

        [flagsMap setObject:[NSNumber numberWithBool:flags.blocked] forKey:@"blocked"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.builtOffline] forKey:@"buildOffline"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.deadJam] forKey:@"deadJam"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.forParking] forKey:@"forParking"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.futureBlocked] forKey:@"futureBlocked"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.hasCheckpoints] forKey:@"hasCheckpoints"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.hasFerries] forKey:@"hasFerries"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.hasFordCrossing] forKey:@"hasFordCrossing"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.hasInPoorConditionRoads] forKey:@"hasInPoorConditionRoads"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.hasRailwayCrossing] forKey:@"hasRailwayCrossing"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.hasRuggedRoads] forKey:@"hasRuggedRoads"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.hasTolls] forKey:@"hasTolls"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.hasUnpavedRoads] forKey:@"hasUnpavedRoads"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.scheduledDeparture] forKey:@"scheduledDeparture"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.requiresAccessPass] forKey:@"requiresAccessPass"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.predicted] forKey:@"predicted"];
        [flagsMap setObject:[NSNumber numberWithBool:flags.hasVehicleRestrictions] forKey:@"hasVehicleRestrictions"];

        [metadata setObject:flagsMap forKey:@"flags"];
    }

    [jsonRoute setObject:metadata forKey:@"metadata"];
}

- (void)populateDrivingInfo:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute routeIndex:(int)routeIndex {
    [self populateSpeedLimits:route json:jsonRoute];
    [self populateSpeedBumps:route json:jsonRoute];
    [self populateCheckpoints:route json:jsonRoute];
    [self populateRuggedRoads:route json:jsonRoute];
    [self populateTollRoads:route json:jsonRoute];
    [self populateFerries:route json:jsonRoute];
    [self populateTrafficLights:route json:jsonRoute];
    [self populateStandingSegments:route json:jsonRoute];
    [self populateAnnotationLanguage:route json:jsonRoute];
    [self populateRequestPoints:route json:jsonRoute];
    [self populateWayPoints:route json:jsonRoute];
    [self populateLaneSigns:route json:jsonRoute];
    [self populateRailwayCrossings:route json:jsonRoute];
    [self populatePedestrianCrossings:route json:jsonRoute];
    [self populateFordCrossings:route json:jsonRoute];
    [self populateSections:route json:jsonRoute routeIndex:routeIndex];
}

- (void)populateSections:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute routeIndex:(int)routeIndex {
    NSMutableArray* sections = [[NSMutableArray alloc] init];
    NSArray<YMKDrivingSection *> *_sections = [route sections];
    for (int j = 0; j < [_sections count]; ++j) {
        NSDictionary *jsonSection = [self convertDrivingRouteSection:route withSection: [_sections objectAtIndex:j] withRouteIndex:routeIndex];
        [sections addObject:jsonSection];
    }
    [jsonRoute setValue:sections forKey:@"sections"];
}

- (void)populateSectionMetadata:(YMKDrivingSection*)section json:(NSMutableDictionary*)sectionJson {
    NSMutableDictionary *metadataJson = [[NSMutableDictionary alloc] init];

    YMKDrivingSectionMetadata *metadata = [section metadata];

    NSMutableDictionary *sectionWeightData = [[NSMutableDictionary alloc] init];
    [sectionWeightData setObject:metadata.weight.time.text forKey:@"time"];
    [sectionWeightData setObject:metadata.weight.timeWithTraffic.text forKey:@"timeWithTraffic"];
    [sectionWeightData setObject:@(metadata.weight.distance.value) forKey:@"distance"];
    [metadataJson setObject:sectionWeightData forKey:@"weight"];

    [metadataJson setObject:@([metadata legIndex]) forKey:@"legIndex"];

    [self populateAnnotation:[metadata annotation] json:metadataJson];

    if ([metadata schemeId] != nil && ![[metadata schemeId] isEqual:[NSNull null]]) {
        [metadataJson setValue:[metadata schemeId] forKey:@"schemeId"];
    }

    NSMutableArray *viaPointsJson = [[NSMutableArray alloc] init];
    NSArray<NSNumber*> *points = [metadata viaPointPositions];
    for (int i = 0; i < [points count]; i++) {
        [viaPointsJson addObject:[points objectAtIndex:i]];
    }

    [metadataJson setValue:viaPointsJson forKey:@"viaPointPositions"];

    [sectionJson setValue:metadataJson forKey:@"metadata"];
}

- (void)populateAnnotation:(YMKDrivingAnnotation*)annotation json:(NSMutableDictionary*)metadataJson {
    NSMutableDictionary *annotationJson = [[NSMutableDictionary alloc] init];
    NSNumber *actionId = [annotation action];
    if (actionId != nil && ![actionId isEqual:[NSNull null]]) {
        [annotationJson setValue:[self getActionById:[actionId intValue]] forKey:@"action"];
    }

    if ([annotation toponym] != nil) {
        [annotationJson setValue:[annotation toponym] forKey:@"toponym"];
    }

    [annotationJson setValue:[annotation descriptionText] forKey:@"description"];

    YMKDrivingActionMetadata *actionMetadata = [annotation actionMetadata];
    NSMutableDictionary *actionMetadataJson = [[NSMutableDictionary alloc] init];
    if ([actionMetadata uturnMetadata] != nil) {
        [actionMetadataJson setValue:@([[actionMetadata uturnMetadata] length]) forKey:@"uTurnLength"];
    }

    if ([actionMetadata leaveRoundaboutMetadada] != nil) {
        [actionMetadataJson setValue:@([[actionMetadata leaveRoundaboutMetadada] exitNumber]) forKey:@"leaveRoundaboutExitNumber"];
    }

    [annotationJson setValue:actionMetadataJson forKey:@"actionMetadata"];

    if ([annotation toponymPhrase] != nil) {
        [annotationJson setValue:[[annotation toponymPhrase] text] forKey:@"toponymPhrase"];
    }

    YMKDrivingHDAnnotation *hdAnnotation = [annotation hdAnnotation];
    if (hdAnnotation != nil) {
        NSMutableDictionary *hdAnnotationJson = [[NSMutableDictionary alloc] init];

        if ([hdAnnotation actionArea] != nil) {
            NSMutableArray *pointsJson = [[NSMutableArray alloc] init];
            NSArray<YMKPoint*> *points = [[hdAnnotation actionArea] points];
            for (int i = 0; i < [points count]; i++) {
                [pointsJson addObject:[self createMapFromPoint:[points objectAtIndex:i]]];
            }

            [hdAnnotation setValue:pointsJson forKey:@"actionAreaPoint"];
        }

        if ([hdAnnotation trajectory] != nil) {
            NSMutableArray *pointsJson = [[NSMutableArray alloc] init];
            NSArray<YMKPoint*> *points = [[hdAnnotation trajectory] points];
            for (int i = 0; i < [points count]; i++) {
                [pointsJson addObject:[self createMapFromPoint:[points objectAtIndex:i]]];
            }

            [hdAnnotation setValue:pointsJson forKey:@"trajectory"];
        }

        [annotationJson setValue:hdAnnotationJson forKey:@"hdAnnotation"];
    }

    [metadataJson setValue:annotationJson forKey:@"annotation"];
}

- (void)populateRailwayCrossings:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingRailwayCrossing *> *crossings = [route railwayCrossings];
    if (crossings != nil) {
        NSMutableArray *crossingsArray = [[NSMutableArray alloc] init];
        for (YMKDrivingRailwayCrossing *crossing in crossings) {
            NSMutableDictionary *crossingJson = [[NSMutableDictionary alloc] init];
            [crossingJson setValue:[self createMapFromPolyline:[crossing position]] forKey:@"position"];

            NSString *type = nil;

            switch ([crossing type]) {
                case YMKDrivingRailwayCrossingTypeUnknown:
                    type = @"UNKNOWN";
                    break;
                case YMKDrivingRailwayCrossingTypeRegular:
                    type = @"REGULAR";
                    break;
                default:
                    type = @"UNKNOWN";
                    break;
            }

            [crossingJson setValue:type forKey:@"type"];

            [crossingsArray addObject:crossingJson];
        }
        [jsonRoute setValue:crossingsArray forKey:@"railwayCrossing"];
    }
}

- (void)populatePedestrianCrossings:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingPedestrianCrossing *> *crossings = [route pedestrianCrossings];
    if (crossings != nil) {
        NSMutableArray *crossingsArray = [[NSMutableArray alloc] init];
        for (YMKDrivingRailwayCrossing *crossing in crossings) {
            NSMutableDictionary *crossingJson = [[NSMutableDictionary alloc] init];
            [crossingJson setValue:[self createMapFromPolyline:[crossing position]] forKey:@"position"];
            [crossingsArray addObject:crossingJson];
        }
        [jsonRoute setValue:crossingsArray forKey:@"pedestrianCrossing"];
    }
}

- (void)populateFordCrossings:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingFordCrossing *> *crossings = [route fordCrossings];
    if (crossings != nil) {
        NSMutableArray *crossingsArray = [[NSMutableArray alloc] init];
        for (YMKDrivingRailwayCrossing *crossing in crossings) {
            NSMutableDictionary *crossingJson = [[NSMutableDictionary alloc] init];
            [crossingJson setValue:[self createMapFromPolyline:[crossing position]] forKey:@"position"];
            [crossingsArray addObject:crossingJson];
        }
        [jsonRoute setValue:crossingsArray forKey:@"fordCrossing"];
    }
}

- (void)populateSpeedLimits:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<NSNumber *> *speedLimits = [route speedLimits];
    if (speedLimits != nil) {
        NSMutableArray *speedLimitArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [speedLimits count]; i++) {
            NSNumber *speedLimitNumber = [speedLimits objectAtIndex:i];
            if (speedLimitNumber != nil && ![speedLimitNumber isEqual:[NSNull null]]) {
                [speedLimitArray addObject:speedLimitNumber];
            } else {
                [speedLimitArray addObject:@(-1)];
            }

        }
        [jsonRoute setObject:speedLimitArray forKey:@"speedLimits"];
    }
}

- (void)populateWayPoints:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKPolylinePosition *> *wayPoints = [route wayPoints];
    if (wayPoints != nil) {
        NSMutableArray *wayPointsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [wayPoints count]; i++) {
            [wayPointsArray addObject:[self createMapFromPolyline:[wayPoints objectAtIndex:i]]];
        }
        [jsonRoute setObject:wayPointsArray forKey:@"wayPoints"];
    }
}


- (void)populateSpeedBumps:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingSpeedBump *> *speedBumps = [route speedBumps];
    if (speedBumps != nil) {
        NSMutableArray *speedBumpsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [speedBumps count]; i++) {
            YMKPolylinePosition *position = [[speedBumps objectAtIndex:i] position];
            [speedBumpsArray addObject:[self createMapFromPolyline:position]];
        }
        [jsonRoute setObject:speedBumpsArray forKey:@"speedBumps"];
    }
}

- (void)populateRequestPoints:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKRequestPoint *> *requestPoints = [route requestPoints];
    if (requestPoints != nil) {
        NSMutableArray *requestPointsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [requestPoints count]; i++) {
            YMKRequestPoint *requestPoint = [requestPoints objectAtIndex:i];
            NSMutableDictionary *requestPointJson = [[NSMutableDictionary alloc] init];
            [requestPointJson setValue:[self createMapFromPoint:[requestPoint point]] forKey:@"point"];

            NSString *type = nil;

            switch ([requestPoint type]) {
                case YMKRequestPointTypeWaypoint:
                    type = @"WAYPOINT";
                    break;
                case YMKRequestPointTypeViapoint:
                    type = @"VIAPOINT";
                    break;
                default:
                    type = @"WAYPOINT";
                    break;
            }

            [requestPointJson setValue:type forKey:@"type"];

            if ([requestPoint pointContext] != nil) {
                [requestPointJson setValue:[requestPoint pointContext] forKey:@"pointContext"];
            }


            [requestPointsArray addObject:requestPointJson];
        }
        [jsonRoute setObject:requestPointsArray forKey:@"requestPoints"];
    }
}

- (void)populateTrafficLights:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingTrafficLight *> *trafficLights = [route trafficLights];
    if (trafficLights != nil) {
        NSMutableArray *trafficLightsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [trafficLights count]; i++) {
            YMKPolylinePosition *position = [[trafficLights objectAtIndex:i] position];
            [trafficLightsArray addObject:[self createMapFromPolyline:position]];
        }
        [jsonRoute setObject:trafficLightsArray forKey:@"trafficLights"];
    }
}

- (void)populateAnnotationLanguage:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    if ([route annotationLanguage] != nil) {
        [jsonRoute setObject:[route annotationLanguage] forKey:@"annotationLanguage"];
    }
}

- (void)populateFerries:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingFerry *> *ferries = [route ferries];
    if (ferries != nil) {
        NSMutableArray *ferriesArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [ferries count]; i++) {
            YMKSubpolyline *position = [[ferries objectAtIndex:i] position];
            NSMutableDictionary *positionJson = [[NSMutableDictionary alloc] init];
            [positionJson setValue:[self createMapFromPolyline:[position begin]] forKey:@"begin"];
            [positionJson setValue:[self createMapFromPolyline:[position end]] forKey:@"end"];

            NSMutableDictionary *ferryJson = [[NSMutableDictionary alloc] init];
            [ferryJson setValue:positionJson forKey:@"position"];

            [ferriesArray addObject:ferryJson];
        }
        [jsonRoute setObject:ferriesArray forKey:@"ferries"];
    }
}

- (void)populateStandingSegments:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingStandingSegment *> *standingSegments = [route standingSegments];
    if (standingSegments != nil) {
        NSMutableArray *standingSegmentsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [standingSegments count]; i++) {
            YMKSubpolyline *position = [[standingSegments objectAtIndex:i] position];
            NSMutableDictionary *positionJson = [[NSMutableDictionary alloc] init];
            [positionJson setValue:[self createMapFromPolyline:[position begin]] forKey:@"begin"];
            [positionJson setValue:[self createMapFromPolyline:[position end]] forKey:@"end"];

            NSMutableDictionary *standingSegmentJson = [[NSMutableDictionary alloc] init];
            [standingSegmentJson setValue:positionJson forKey:@"position"];

            [standingSegmentsArray addObject:standingSegmentJson];
        }
        [jsonRoute setObject:standingSegmentsArray forKey:@"standingSegments"];
    }
}

- (void)populateCheckpoints:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingCheckpoint *> *checkpoints = [route checkpoints];
    if (checkpoints != nil) {
        NSMutableArray *checkpointsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [checkpoints count]; i++) {
            YMKPolylinePosition *position = [[checkpoints objectAtIndex:i] position];
            [checkpointsArray addObject:[self createMapFromPolyline:position]];
        }
        [jsonRoute setObject:checkpointsArray forKey:@"speedBumps"];
    }
}

- (void)populateRuggedRoads:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingRuggedRoad *> *ruggedRoads = [route ruggedRoads];
    if (ruggedRoads != nil) {
        NSMutableArray *ruggedRoadsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [ruggedRoads count]; i++) {
            YMKDrivingRuggedRoad *ruggedRoad = [ruggedRoads objectAtIndex:i];

            YMKSubpolyline *position = [ruggedRoad position];
            NSMutableDictionary *positionJson = [[NSMutableDictionary alloc] init];
            [positionJson setValue:[self createMapFromPolyline:[position begin]] forKey:@"begin"];
            [positionJson setValue:[self createMapFromPolyline:[position end]] forKey:@"end"];

            NSMutableDictionary *ruggedRoadJson = [[NSMutableDictionary alloc] init];
            [ruggedRoadJson setValue:positionJson forKey:@"position"];
            [ruggedRoadJson setValue:[NSNumber numberWithBool:[ruggedRoad inPoorCondition]] forKey:@"inPoorCondition"];
            [ruggedRoadJson setValue:[NSNumber numberWithBool:[ruggedRoad unpaved]] forKey:@"unpaved"];

            [ruggedRoadsArray addObject:ruggedRoadJson];
        }
        [jsonRoute setObject:ruggedRoadsArray forKey:@"ruggedRoads"];
    }
}

/*- (void)populateDirectionSigns:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingDirectionSign *> *directionSigns = [route directionSigns];
    if (directionSigns != nil) {
        NSMutableArray *directionSignsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [directionSigns count]; i++) {
            YMKDrivingDirectionSign *directionSign = [directionSigns objectAtIndex:i];

            NSMutableDictionary *directionSignJson = [[NSMutableDictionary alloc] init];

            [directionSignJson setValue:[self createMapFromPolyline:[directionSign position]] forKey:@"position"];

            NSNumber *direction = [directionSign direction];
            if (direction != nil && ![direction isEqual:[NSNull null]]) {
                int modifiedDirectionId = [direction intValue] + 1;
                [directionSignJson setValue:[self getDirectionById:modifiedDirectionId] forKey:@"direction"];
            }

            NSArray<YMKDrivingDirectionSignItem *> *directionSignsItem = [directionSign items];
            NSMutableArray *itemsArray = [[NSMutableArray alloc] init];
            for (YMKDrivingDirectionSignItem *item in directionSignsItem) {
                NSMutableDictionary *directionSignItemJson = [[NSMutableDictionary alloc] init];

                YMKDrivingDirectionSignToponym *toponym = [item toponym];
                if (toponym != nil) {
                    NSMutableDictionary *toponymJson = [[NSMutableDictionary alloc] init];
                    [toponymJson setValue:[toponym text] forKey:@"text"];

                }
            }
            [directionSignJson setValue:itemsArray forKey:@"items"];
        }
        [jsonRoute setObject:directionSignsArray forKey:@"directionSigns"];
    }
}*/

/*-(void)addSignStyle:(YMKDrivingDirectionSignStyle*)style json:(NSMutableDictionary*)item {
    NSMutableDictionary *styleJson = [[NSMutableDictionary alloc] init];
    [styleJson setValue:[style textColor] forKey:@"textColor"];
}*/

- (void)populateLaneSigns:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingLaneSign *> *laneSigns = [route laneSigns];
    if (laneSigns != nil) {
        NSMutableArray *laneSignsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [laneSigns count]; i++) {
            YMKDrivingLaneSign *laneSign = [laneSigns objectAtIndex:i];

            NSMutableDictionary *laneSignJson = [[NSMutableDictionary alloc] init];
            [laneSignJson setValue:[self createMapFromPolyline:[laneSign position]] forKey:@"position"];

            NSArray<YMKDrivingLane *> *lanes = [laneSign lanes];
            if (lanes != nil) {
                NSMutableArray *lanesArray = [[NSMutableArray alloc] init];
                for (int j = 0; j < [lanes count]; j++) {
                    YMKDrivingLane *lane = [lanes objectAtIndex:j];

                    NSMutableDictionary *laneJson = [[NSMutableDictionary alloc] init];

                    if ([lane highlightedDirection] != nil) {
                        [laneJson setValue:[self getDirectionById:[[lane highlightedDirection] intValue]] forKey:@"highlightedDirection"];
                    }

                    NSString *laneKind = nil;

                    switch ([lane laneKind]) {
                        case YMKDrivingLaneKindUnknownKind:
                            laneKind = @"UNKNOWN_KIND";
                            break;
                        case YMKDrivingLaneKindPlainLane:
                            laneKind = @"PLAIN_LANE";
                            break;
                        case YMKDrivingLaneKindBusLane:
                            laneKind = @"BUS_LANE";
                            break;
                        case YMKDrivingLaneKindTramLane:
                            laneKind = @"TRAM_LANE";
                            break;
                        case YMKDrivingLaneKindTaxiLane:
                            laneKind = @"TAXI_LANE";
                            break;
                        case YMKDrivingLaneKindBikeLane:
                            laneKind = @"BIKE_LANE";
                            break;
                        default:
                            laneKind = @"UNKNOWN_KIND";
                            break;
                    }

                    [laneJson setValue:laneKind forKey:@"laneKind"];

                    NSArray<NSNumber *> *directions = [lane directions];
                    if (directions != nil) {
                        NSMutableArray *directionsArray = [[NSMutableArray alloc] init];
                        for (int k = 0; k < [directions count]; k++) {
                            [directionsArray addObject:[self getDirectionById:[[directions objectAtIndex:k] intValue]]];
                        }
                        [laneJson setValue:directionsArray forKey:@"directions"];
                    }

                    [lanesArray addObject:laneJson];
                }
                [laneSignJson setValue:lanesArray forKey:@"lanes"];
            }

            [laneSignsArray addObject:laneSignJson];
        }
        [jsonRoute setObject:laneSignsArray forKey:@"laneSigns"];
    }
}

- (NSString *)getDirectionById:(int)directionId {
    NSString *direction = nil;

    switch (directionId) {
        case 0:
            direction = @"UNKNOWN_DIRECTION";
            break;
        case 1:
            direction = @"LEFT180";
            break;
        case 2:
            direction = @"LEFT135";
            break;
        case 3:
            direction = @"LEFT90";
            break;
        case 4:
            direction = @"LEFT45";
            break;
        case 5:
            direction = @"STRAIGHT_AHEAD";
            break;
        case 6:
            direction = @"RIGHT45";
            break;
        case 7:
            direction = @"RIGHT90";
            break;
        case 8:
            direction = @"RIGHT135";
            break;
        case 9:
            direction = @"RIGHT180";
            break;
        case 10:
            direction = @"LEFT_FROM_RIGHT";
            break;
        case 11:
            direction = @"RIGHT_FROM_LEFT";
            break;
        case 12:
            direction = @"LEFT_SHIFT";
            break;
        case 13:
            direction = @"RIGHT_SHIFT";
            break;
        default:
            direction = @"UNKNOWN_DIRECTION";
            break;
    }
    return direction;
}

- (NSString *)getActionById:(int)actionId {
    NSString *action = nil;

    switch (actionId) {
        case 0:
            action = @"UNKNOWN";
            break;
        case 1:
            action = @"STRAIGHT";
            break;
        case 2:
            action = @"SLIGHT_LEFT";
            break;
        case 3:
            action = @"SLIGHT_RIGHT";
            break;
        case 4:
            action = @"LEFT";
            break;
        case 5:
            action = @"RIGHT";
            break;
        case 6:
            action = @"HARD_LEFT";
            break;
        case 7:
            action = @"HARD_RIGHT";
            break;
        case 8:
            action = @"FORK_LEFT";
            break;
        case 9:
            action = @"FORK_RIGHT";
            break;
        case 10:
            action = @"UTURN_LEFT";
            break;
        case 11:
            action = @"UTURN_RIGHT";
            break;
        case 12:
            action = @"ENTER_ROUNDABOUT";
            break;
        case 13:
            action = @"LEAVE_ROUNDABOUT";
            break;
        case 14:
            action = @"BOARD_FERRY";
            break;
        case 15:
            action = @"LEAVE_FERRY";
            break;
        case 16:
            action = @"EXIT_LEFT";
            break;
        case 17:
            action = @"EXIT_RIGHT";
            break;
        case 18:
            action = @"FINISH";
            break;
        case 19:
            action = @"WAYPOINT";
            break;
        default:
            action = @"UNKNOWN";
            break;
    }
    return action;
}

- (void)populateTollRoads:(YMKDrivingRoute*)route json:(NSMutableDictionary*)jsonRoute {
    NSArray<YMKDrivingTollRoad *> *tollRoads = [route tollRoads];
    if (tollRoads != nil) {
        NSMutableArray *tollRoadArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [tollRoads count]; i++) {
            YMKDrivingTollRoad *tollRoad = [tollRoads objectAtIndex:i];

            YMKSubpolyline *position = [tollRoad position];
            NSMutableDictionary *positionJson = [[NSMutableDictionary alloc] init];
            [positionJson setValue:[self createMapFromPolyline:[position begin]] forKey:@"begin"];
            [positionJson setValue:[self createMapFromPolyline:[position end]] forKey:@"end"];

            NSMutableDictionary *tollRoadJson = [[NSMutableDictionary alloc] init];
            [tollRoadJson setValue:positionJson forKey:@"position"];

            [tollRoadArray addObject:tollRoadJson];
        }
        [jsonRoute setObject:tollRoadArray forKey:@"tollRoads"];
    }
}

- (NSDictionary*)createMapFromPoint:(YMKPoint*)point {
    NSMutableDictionary *pointJson = [[NSMutableDictionary alloc] init];
    [pointJson setValue:[NSNumber numberWithDouble:point.latitude] forKey:@"lat"];
    [pointJson setValue:[NSNumber numberWithDouble:point.longitude] forKey:@"lon"];
    return pointJson;
}

- (NSDictionary*)createMapFromPolyline:(YMKPolylinePosition*)polyline {
    NSMutableDictionary *polylineJson = [[NSMutableDictionary alloc] init];
    [polylineJson setValue:[NSNumber numberWithDouble:polyline.segmentIndex] forKey:@"segmentIndex"];
    [polylineJson setValue:[NSNumber numberWithDouble:polyline.segmentPosition] forKey:@"segmentPosition"];
    return polylineJson;
}

- (UIImage*)resolveUIImage:(NSString*)uri {
    UIImage *icon;

    if ([uri rangeOfString:@"http://"].location == NSNotFound && [uri rangeOfString:@"https://"].location == NSNotFound) {
        if ([uri rangeOfString:@"file://"].location != NSNotFound){
            NSString *file = [uri substringFromIndex:8];
            icon = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:file]]];
        } else {
            icon = [UIImage imageNamed:uri];
        }
    } else {
        icon = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:uri]]];
    }

    return icon;
}

- (void)onReceiveNativeEvent:(NSDictionary *)response {
    if (self.onRouteFound)
        self.onRouteFound(response);
}

- (void)removeAllSections {
    [self.mapWindow.map.mapObjects clear];
}

// REF
- (void)setCenter:(YMKCameraPosition *)position withDuration:(float)duration withAnimation:(int)animation {
    if (duration > 0) {
        YMKAnimationType anim = animation == 0 ? YMKAnimationTypeSmooth : YMKAnimationTypeLinear;
        [self.mapWindow.map moveWithCameraPosition:position animationType:[YMKAnimation animationWithType:anim duration: duration] cameraCallback:^(BOOL completed) {}];
    } else {
        [self.mapWindow.map moveWithCameraPosition:position];
    }
}

- (void)setZoom:(float)zoom withDuration:(float)duration withAnimation:(int)animation {
    YMKCameraPosition *prevPosition = self.mapWindow.map.cameraPosition;
    YMKCameraPosition *position = [YMKCameraPosition cameraPositionWithTarget:prevPosition.target zoom:zoom azimuth:prevPosition.azimuth tilt:prevPosition.tilt];
    [self setCenter:position withDuration:duration withAnimation:animation];
}

- (void)setMapType:(NSString *)type {
    if ([type isEqual:@"none"]) {
        self.mapWindow.map.mapType = YMKMapTypeNone;
    } else if ([type isEqual:@"raster"]) {
        self.mapWindow.map.mapType = YMKMapTypeMap;
    } else {
        self.mapWindow.map.mapType = YMKMapTypeVectorMap;
    }
}

- (void)setInitialRegion:(NSDictionary *)initialParams {
    if ([initialParams valueForKey:@"lat"] == nil || [initialParams valueForKey:@"lon"] == nil) return;

    float initialZoom = 10.f;
    float initialAzimuth = 0.f;
    float initialTilt = 0.f;

    if ([initialParams valueForKey:@"zoom"] != nil) initialZoom = [initialParams[@"zoom"] floatValue];

    if ([initialParams valueForKey:@"azimuth"] != nil) initialTilt = [initialParams[@"azimuth"] floatValue];

    if ([initialParams valueForKey:@"tilt"] != nil) initialTilt = [initialParams[@"tilt"] floatValue];

    YMKPoint *initialRegionCenter = [RCTConvert YMKPoint:@{@"lat" : [initialParams valueForKey:@"lat"], @"lon" : [initialParams valueForKey:@"lon"]}];
    YMKCameraPosition *initialRegioPosition = [YMKCameraPosition cameraPositionWithTarget:initialRegionCenter zoom:initialZoom azimuth:initialAzimuth tilt:initialTilt];
    [self.mapWindow.map moveWithCameraPosition:initialRegioPosition];
}

- (void)setTrafficVisible:(BOOL)traffic {
    YMKMapKit *inst = [YMKMapKit sharedInstance];

    if (trafficLayer == nil) {
        trafficLayer = [inst createTrafficLayerWithMapWindow:self.mapWindow];
    }

    if (traffic) {
        [trafficLayer setTrafficVisibleWithOn:YES];
        [trafficLayer addTrafficListenerWithTrafficListener:self];
    } else {
        [trafficLayer setTrafficVisibleWithOn:NO];
        [trafficLayer removeTrafficListenerWithTrafficListener:self];
    }
}

- (NSDictionary *)cameraPositionToJSON:(YMKCameraPosition *)position reason:(YMKCameraUpdateReason)reason finished:(BOOL)finished {
    return @{
        @"azimuth": [NSNumber numberWithFloat:position.azimuth],
        @"tilt": [NSNumber numberWithFloat:position.tilt],
        @"zoom": [NSNumber numberWithFloat:position.zoom],
        @"point": @{
            @"lat": [NSNumber numberWithDouble:position.target.latitude],
            @"lon": [NSNumber numberWithDouble:position.target.longitude]
        },
        @"reason": reason == 0 ? @"GESTURES" : @"APPLICATION",
        @"finished": @(finished)
    };
}

- (NSDictionary *)worldPointToJSON:(YMKPoint *)point {
    return @{
        @"lat": [NSNumber numberWithDouble:point.latitude],
        @"lon": [NSNumber numberWithDouble:point.longitude]
    };
}

- (NSDictionary *)screenPointToJSON:(YMKScreenPoint *)point {
    return @{
        @"x": [NSNumber numberWithFloat:point.x],
        @"y": [NSNumber numberWithFloat:point.y]
    };
}

- (NSDictionary *)visibleRegionToJSON:(YMKVisibleRegion *)region {
    return @{
        @"bottomLeft": @{
            @"lat": [NSNumber numberWithDouble:region.bottomLeft.latitude],
            @"lon": [NSNumber numberWithDouble:region.bottomLeft.longitude]
        },
        @"bottomRight": @{
            @"lat": [NSNumber numberWithDouble:region.bottomRight.latitude],
            @"lon": [NSNumber numberWithDouble:region.bottomRight.longitude]
        },
        @"topLeft": @{
            @"lat": [NSNumber numberWithDouble:region.topLeft.latitude],
            @"lon": [NSNumber numberWithDouble:region.topLeft.longitude]
        },
        @"topRight": @{
            @"lat": [NSNumber numberWithDouble:region.topRight.latitude],
            @"lon": [NSNumber numberWithDouble:region.topRight.longitude]
        }
    };
}

- (void)emitCameraPositionToJS:(NSString *)_id {
    YMKCameraPosition *position = self.mapWindow.map.cameraPosition;
    NSDictionary *cameraPosition = [self cameraPositionToJSON:position reason:1 finished:YES];
    NSMutableDictionary *response = [NSMutableDictionary dictionaryWithDictionary:cameraPosition];
    [response setValue:_id forKey:@"id"];

    if (self.onCameraPositionReceived) {
        self.onCameraPositionReceived(response);
    }
}

- (void)emitVisibleRegionToJS:(NSString *)_id {
    YMKVisibleRegion *region = self.mapWindow.map.visibleRegion;
    NSDictionary *visibleRegion = [self visibleRegionToJSON:region];
    NSMutableDictionary *response = [NSMutableDictionary dictionaryWithDictionary:visibleRegion];
    [response setValue:_id forKey:@"id"];

    if (self.onVisibleRegionReceived) {
        self.onVisibleRegionReceived(response);
    }
}

- (void)emitWorldToScreenPoint:(NSArray<YMKPoint *> *)worldPoints withId:(NSString *)_id {
    NSMutableArray *screenPoints = [[NSMutableArray alloc] init];

    for (int i = 0; i < [worldPoints count]; ++i) {
        YMKScreenPoint *screenPoint = [self.mapWindow worldToScreenWithWorldPoint:[worldPoints objectAtIndex:i]];
        [screenPoints addObject:[self screenPointToJSON:screenPoint]];
    }

    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    [response setValue:_id forKey:@"id"];
    [response setValue:screenPoints forKey:@"screenPoints"];

    if (self.onWorldToScreenPointsReceived) {
        self.onWorldToScreenPointsReceived(response);
    }
}

- (void)emitScreenToWorldPoint:(NSArray<YMKScreenPoint *> *)screenPoints withId:(NSString *)_id {
    NSMutableArray *worldPoints = [[NSMutableArray alloc] init];

    for (int i = 0; i < [screenPoints count]; ++i) {
        YMKPoint *worldPoint = [self.mapWindow screenToWorldWithScreenPoint:[screenPoints objectAtIndex:i]];
        [worldPoints addObject:[self worldPointToJSON:worldPoint]];
    }

    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    [response setValue:_id forKey:@"id"];
    [response setValue:worldPoints forKey:@"worldPoints"];

    if (self.onScreenToWorldPointsReceived) {
        self.onScreenToWorldPointsReceived(response);
    }
}

- (void)onCameraPositionChangedWithMap:(nonnull YMKMap*)map
                        cameraPosition:(nonnull YMKCameraPosition*)cameraPosition
                    cameraUpdateReason:(YMKCameraUpdateReason)cameraUpdateReason
                              finished:(BOOL)finished {
    if (self.onCameraPositionChange) {
        self.onCameraPositionChange([self cameraPositionToJSON:cameraPosition reason:cameraUpdateReason finished:finished]);
    }

    if (self.onCameraPositionChangeEnd && finished) {
        self.onCameraPositionChangeEnd([self cameraPositionToJSON:cameraPosition reason:cameraUpdateReason finished:finished]);
    }
}

- (void)setNightMode:(BOOL)nightMode {
    [self.mapWindow.map setNightModeEnabled:nightMode];
}


- (void)setListenUserLocation:(BOOL) listen {
    YMKMapKit *inst = [YMKMapKit sharedInstance];

    if (userLayer == nil) {
        userLayer = [inst createUserLocationLayerWithMapWindow:self.mapWindow];
    }

    if (listen) {
        [userLayer setVisibleWithOn:YES];
        [userLayer setObjectListenerWithObjectListener:self];
    } else {
        [userLayer setVisibleWithOn:NO];
        [userLayer setObjectListenerWithObjectListener:nil];
    }
}

- (void)setFollowUser:(BOOL)follow {
    if (userLayer == nil) {
        [self setListenUserLocation: follow];
    }

    if (follow) {
        CGFloat scale = UIScreen.mainScreen.scale;
        [userLayer setAnchorWithAnchorNormal:CGPointMake(0.5 * self.mapWindow.width, 0.5 * self.mapWindow.height) anchorCourse:CGPointMake(0.5 * self.mapWindow.width, 0.83 * self.mapWindow.height )];
        [userLayer setAutoZoomEnabled:YES];
    } else {
        [userLayer setAutoZoomEnabled:NO];
        [userLayer resetAnchor];
    }
}

- (void)fitAllMarkers {
    NSMutableArray<YMKPoint *> *lastKnownMarkers = [[NSMutableArray alloc] init];

    for (int i = 0; i < [_reactSubviews count]; ++i) {
        UIView *view = [_reactSubviews objectAtIndex:i];

        if ([view isKindOfClass:[YamapMarkerView class]]) {
            YamapMarkerView *marker = (YamapMarkerView *)view;
            [lastKnownMarkers addObject:[marker getPoint]];
        }
    }

    [self fitMarkers:lastKnownMarkers];
}

- (NSArray<YMKPoint *> *)mapPlacemarksToPoints:(NSArray<YMKPlacemarkMapObject *> *)placemarks {
    NSMutableArray<YMKPoint *> *points = [[NSMutableArray alloc] init];

    for (int i = 0; i < [placemarks count]; ++i) {
        [points addObject:[[placemarks objectAtIndex:i] geometry]];
    }

    return points;
}

- (YMKBoundingBox *)calculateBoundingBox:(NSArray<YMKPoint *> *) points {
    double minLon = [points[0] longitude], maxLon = [points[0] longitude];
    double minLat = [points[0] latitude], maxLat = [points[0] latitude];

    for (int i = 0; i < [points count]; i++) {
        if ([points[i] longitude] > maxLon) maxLon = [points[i] longitude];
        if ([points[i] longitude] < minLon) minLon = [points[i] longitude];
        if ([points[i] latitude] > maxLat) maxLat = [points[i] latitude];
        if ([points[i] latitude] < minLat) minLat = [points[i] latitude];
    }

    double latDelta = maxLat - minLat;
    double lonDelta = maxLon - minLon;

    YMKPoint *southWest;
    YMKPoint *northEast;

    if (latDelta > lonDelta) {
        southWest = [YMKPoint pointWithLatitude:minLat - latDelta longitude:minLon];
        northEast = [YMKPoint pointWithLatitude:maxLat - latDelta / 2.5 longitude:maxLon];
    } else {
        southWest = [YMKPoint pointWithLatitude:minLat - lonDelta / 2 longitude:minLon];
        northEast = [YMKPoint pointWithLatitude:maxLat - lonDelta / 2 longitude:maxLon];
    }

    YMKBoundingBox *boundingBox = [YMKBoundingBox boundingBoxWithSouthWest:southWest northEast:northEast];
    return boundingBox;
}

- (void)fitMarkers:(NSArray<YMKPoint *> *) points {
    if ([points count] == 1) {
        YMKPoint *center = [points objectAtIndex:0];
        [self.mapWindow.map moveWithCameraPosition:[YMKCameraPosition cameraPositionWithTarget:center zoom:15 azimuth:0 tilt:0]];
        return;
    }
    YMKCameraPosition *cameraPosition = [self.mapWindow.map cameraPositionWithBoundingBox:[self calculateBoundingBox:points]];
    cameraPosition = [YMKCameraPosition cameraPositionWithTarget:cameraPosition.target zoom:cameraPosition.zoom - 0.8f azimuth:cameraPosition.azimuth tilt:cameraPosition.tilt];
    [self.mapWindow.map moveWithCameraPosition:cameraPosition animationType:[YMKAnimation animationWithType:YMKAnimationTypeSmooth duration:1.0] cameraCallback:^(BOOL completed){}];
}

- (void)setLogoPosition:(NSDictionary *)logoPosition {
    YMKLogoHorizontalAlignment *horizontalAlignment = YMKLogoHorizontalAlignmentRight;
    YMKLogoVerticalAlignment *verticalAlignment = YMKLogoVerticalAlignmentBottom;

    if ([[logoPosition valueForKey:@"horizontal"] isEqual:@"left"]) {
        horizontalAlignment = YMKLogoHorizontalAlignmentLeft;
    } else if ([[logoPosition valueForKey:@"horizontal"] isEqual:@"center"]) {
        horizontalAlignment = YMKLogoHorizontalAlignmentCenter;
    }

    if ([[logoPosition valueForKey:@"vertical"] isEqual:@"top"]) {
        verticalAlignment = YMKLogoVerticalAlignmentTop;
    }

    [self.mapWindow.map.logo setAlignmentWithAlignment:[YMKLogoAlignment alignmentWithHorizontalAlignment:horizontalAlignment verticalAlignment:verticalAlignment]];
}

- (void)setLogoPadding:(NSDictionary *)logoPadding {
    NSUInteger *horizontalPadding = [logoPadding valueForKey:@"horizontal"] != nil ? [RCTConvert NSUInteger:logoPadding[@"horizontal"]] : 0;
    NSUInteger *verticalPadding = [logoPadding valueForKey:@"vertical"] != nil ? [RCTConvert NSUInteger:logoPadding[@"vertical"]] : 0;

    YMKLogoPadding *padding = [YMKLogoPadding paddingWithHorizontalPadding:horizontalPadding verticalPadding:verticalPadding];
    [self.mapWindow.map.logo setPaddingWithPadding:padding];
}

// PROPS
- (void)setUserLocationIcon:(NSString *)iconSource {
    userLocationImage = [self resolveUIImage:iconSource];
    [self updateUserIcon];
}

- (void)setUserLocationIconScale:(NSNumber *)iconScale {
    userLocationImageScale = iconScale;
    [self updateUserIcon];
}

- (void)setUserLocationAccuracyFillColor:(UIColor *)color {
    userLocationAccuracyFillColor = color;
    [self updateUserIcon];
}

- (void)setUserLocationAccuracyStrokeColor:(UIColor *)color {
    userLocationAccuracyStrokeColor = color;
    [self updateUserIcon];
}

- (void)setUserLocationAccuracyStrokeWidth:(float)width {
    userLocationAccuracyStrokeWidth = width;
    [self updateUserIcon];
}

- (void)updateUserIcon {
    if (userLocationView != nil) {
        if (userLocationImage) {
            YMKIconStyle *userIconStyle = [[YMKIconStyle alloc] init];
            [userIconStyle setScale:userLocationImageScale];

            [userLocationView.pin setIconWithImage:userLocationImage style:userIconStyle];
            [userLocationView.arrow setIconWithImage:userLocationImage style:userIconStyle];
        }

        YMKCircleMapObject* circle = userLocationView.accuracyCircle;

        if (userLocationAccuracyFillColor) {
            [circle setFillColor:userLocationAccuracyFillColor];
        }

        if (userLocationAccuracyStrokeColor) {
            [circle setStrokeColor:userLocationAccuracyStrokeColor];
        }

        [circle setStrokeWidth:userLocationAccuracyStrokeWidth];
    }
}

- (void)onObjectAddedWithView:(nonnull YMKUserLocationView *)view {
    userLocationView = view;
    [self updateUserIcon];
}

- (void)onObjectRemovedWithView:(nonnull YMKUserLocationView *)view {
}

- (void)onObjectUpdatedWithView:(nonnull YMKUserLocationView *)view event:(nonnull YMKObjectEvent *)event {
    userLocationView = view;
    [self updateUserIcon];
}

- (void)onMapTapWithMap:(nonnull YMKMap *)map
                  point:(nonnull YMKPoint *)point {
    if (self.onMapPress) {
        NSDictionary *data = @{
            @"lat": [NSNumber numberWithDouble:point.latitude],
            @"lon": [NSNumber numberWithDouble:point.longitude]
        };
        self.onMapPress(data);
    }
}

- (void)onMapLongTapWithMap:(nonnull YMKMap *)map
                      point:(nonnull YMKPoint *)point {
    if (self.onMapLongPress) {
        NSDictionary *data = @{
            @"lat": [NSNumber numberWithDouble:point.latitude],
            @"lon": [NSNumber numberWithDouble:point.longitude]
        };
        self.onMapLongPress(data);
    }
}

// UTILS
+ (UIColor*)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];

    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (NSString *)hexStringFromColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];

    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

// CHILDREN
- (void)addSubview:(UIView *)view {
    [super addSubview:view];
}

- (void)insertReactSubview:(UIView<RCTComponent> *)subview atIndex:(NSInteger)atIndex {
    if ([subview isKindOfClass:[YamapPolygonView class]]) {
        YMKMapObjectCollection *objects = self.mapWindow.map.mapObjects;
        YamapPolygonView *polygon = (YamapPolygonView *) subview;
        YMKPolygonMapObject *obj = [objects addPolygonWithPolygon:[polygon getPolygon]];
        [polygon setMapObject:obj];
    } else if ([subview isKindOfClass:[YamapPolylineView class]]) {
        YMKMapObjectCollection *objects = self.mapWindow.map.mapObjects;
        YamapPolylineView *polyline = (YamapPolylineView*) subview;
        YMKPolylineMapObject *obj = [objects addPolylineWithPolyline:[polyline getPolyline]];
        [polyline setMapObject:obj];
    } else if ([subview isKindOfClass:[YamapMarkerView class]]) {
        YMKMapObjectCollection *objects = self.mapWindow.map.mapObjects;
        YamapMarkerView *marker = (YamapMarkerView *) subview;
        YMKPlacemarkMapObject *obj = [objects addPlacemarkWithPoint:[marker getPoint]];
        [marker setMapObject:obj];
    } else if ([subview isKindOfClass:[YamapCircleView class]]) {
        YMKMapObjectCollection *objects = self.mapWindow.map.mapObjects;
        YamapCircleView *circle = (YamapCircleView*) subview;
        YMKCircleMapObject *obj = [objects addCircleWithCircle:[circle getCircle] strokeColor:UIColor.blackColor strokeWidth:0.f fillColor:UIColor.blackColor];
        [circle setMapObject:obj];
    } else {
        NSArray<id<RCTComponent>> *childSubviews = [subview reactSubviews];
        for (int i = 0; i < childSubviews.count; i++) {
            [self insertReactSubview:(UIView *)childSubviews[i] atIndex:atIndex];
        }
    }

    [_reactSubviews insertObject:subview atIndex:atIndex];
    [super insertReactSubview:subview atIndex:atIndex];
}

- (void)insertMarkerReactSubview:(UIView<RCTComponent> *) subview atIndex:(NSInteger) atIndex {
    [_reactSubviews insertObject:subview atIndex:atIndex];
    [super insertReactSubview:subview atIndex:atIndex];
}

- (void)removeMarkerReactSubview:(UIView<RCTComponent> *) subview {
    [_reactSubviews removeObject:subview];
    [super removeReactSubview: subview];
}

- (void)removeReactSubview:(UIView<RCTComponent> *)subview {
    if ([subview isKindOfClass:[YamapPolygonView class]]) {
        YMKMapObjectCollection *objects = self.mapWindow.map.mapObjects;
        YamapPolygonView *polygon = (YamapPolygonView *) subview;
        [objects removeWithMapObject:[polygon getMapObject]];
    } else if ([subview isKindOfClass:[YamapPolylineView class]]) {
        YMKMapObjectCollection *objects = self.mapWindow.map.mapObjects;
        YamapPolylineView *polyline = (YamapPolylineView *) subview;
        [objects removeWithMapObject:[polyline getMapObject]];
    } else if ([subview isKindOfClass:[YamapMarkerView class]]) {
        YMKMapObjectCollection *objects = self.mapWindow.map.mapObjects;
        YamapMarkerView *marker = (YamapMarkerView *) subview;
        [objects removeWithMapObject:[marker getMapObject]];
    } else if ([subview isKindOfClass:[YamapCircleView class]]) {
        YMKMapObjectCollection *objects = self.mapWindow.map.mapObjects;
        YamapCircleView *circle = (YamapCircleView *) subview;
        [objects removeWithMapObject:[circle getMapObject]];
    } else {
        NSArray<id<RCTComponent>> *childSubviews = [subview reactSubviews];
        for (int i = 0; i < childSubviews.count; i++) {
            [self removeReactSubview:(UIView *)childSubviews[i]];
        }
    }

    [_reactSubviews removeObject:subview];
    [super removeReactSubview: subview];
}

- (void)onMapLoadedWithStatistics:(YMKMapLoadStatistics*)statistics {
    if (self.onMapLoaded) {
        NSDictionary *data = @{
            @"renderObjectCount": @(statistics.renderObjectCount),
            @"curZoomModelsLoaded": @(statistics.curZoomModelsLoaded),
            @"curZoomPlacemarksLoaded": @(statistics.curZoomPlacemarksLoaded),
            @"curZoomLabelsLoaded": @(statistics.curZoomLabelsLoaded),
            @"curZoomGeometryLoaded": @(statistics.curZoomGeometryLoaded),
            @"tileMemoryUsage": @(statistics.tileMemoryUsage),
            @"delayedGeometryLoaded": @(statistics.delayedGeometryLoaded),
            @"fullyAppeared": @(statistics.fullyAppeared),
            @"fullyLoaded": @(statistics.fullyLoaded),
        };
        self.onMapLoaded(data);
    }
}

- (void)reactSetFrame:(CGRect)frame {
    self.mapFrame = frame;
    [super reactSetFrame:frame];
}

- (void)layoutMarginsDidChange {
    [super reactSetFrame:self.mapFrame];
}

- (void)setMaxFps:(float)maxFps {
    [self.mapWindow setMaxFpsWithFps:maxFps];
}

- (void)setInteractive:(BOOL)interactive {
    [self setNoninteractive:!interactive];
}

- (void)onTrafficChangedWithTrafficLevel:(nullable YMKTrafficLevel *)trafficLevel {
    //TODO
}

- (void)onTrafficLoading {
    //TODO
}

- (void)onTrafficExpired {
    //TODO
}

@synthesize reactTag;

@end

