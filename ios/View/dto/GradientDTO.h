#import <UIKit/UIKit.h>

@interface GradientDTO : NSObject

@property (nonatomic, readonly) float length;
@property (nonatomic, readonly) NSArray<UIColor *> *colors;

- (instancetype)initWithLength:(float)length colors:(NSArray<UIColor *> *)colors;

@end