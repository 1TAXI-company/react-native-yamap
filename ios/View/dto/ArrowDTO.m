#import "ArrowDTO.h"
@import YandexMapsMobile;

@implementation ArrowDTO

- (instancetype)initWithArrowOutlineColor:(UIColor *)arrowOutlineColor
                       arrowOutlineWidth:(float)arrowOutlineWidth
                                   length:(float)length
                               arrowColor:(UIColor *)arrowColor
                                positions:(NSArray<YMKPolylinePosition *> *)positions {
    self = [super init];
    if (self) {
        _arrowOutlineColor = arrowOutlineColor;
        _arrowOutlineWidth = arrowOutlineWidth;
        _length = length;
        _arrowColor = arrowColor;
        _positions = [positions copy];
    }
    return self;
}

@end
