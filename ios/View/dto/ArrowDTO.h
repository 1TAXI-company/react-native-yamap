#import <UIKit/UIKit.h>
@import YandexMapsMobile;

@interface ArrowDTO : NSObject

@property (nonatomic, readonly, nonnull) UIColor *arrowOutlineColor;
@property (nonatomic, readonly) float arrowOutlineWidth;
@property (nonatomic, readonly) float length;
@property (nonatomic, readonly, nonnull) UIColor *arrowColor;
@property (nonatomic, readonly, nonnull) NSArray<YMKPolylinePosition *> *positions;

- (instancetype)initWithArrowOutlineColor:(UIColor *)arrowOutlineColor
                       arrowOutlineWidth:(float)arrowOutlineWidth
                                   length:(float)length
                               arrowColor:(UIColor *)arrowColor
                                positions:(NSArray<YMKPolylinePosition *> *)positions;

@end
