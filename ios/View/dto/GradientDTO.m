
#import "GradientDTO.h"

@implementation GradientDTO


- (instancetype)initWithLength:(float)length colors:(NSArray<UIColor *> *)colors {
    self = [super init];
    if (self) {
        _length = length;
        _colors = [colors copy];
    }
    return self;
}

@end