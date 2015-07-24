
#import "GPUImageFilter.h"

@interface RandomHue : GPUImageFilter
{
  GLint hueAdjustUniform;
  
}
@property (nonatomic, readwrite) CGFloat hue;

@end
