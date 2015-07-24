#import "RandomSwirlFilter.h"

// Adapted from the shader example here: http://www.geeks3d.com/20110428/shader-library-swirl-post-processing-filter-in-glsl/


NSString *const kGPUImageRandomSwirlFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp vec2 center;
 uniform highp float radius;
 uniform highp float angle;
 
 void main()
 {
   highp vec2 textureCoordinateToUse = textureCoordinate;
   highp float dist = distance(center, textureCoordinate);
   if (dist < radius)
   {
     textureCoordinateToUse -= center;
     highp float percent = (radius - dist) / radius;
     highp float theta = percent * percent * angle * 8.0;
     highp float s = sin(theta);
     highp float c = cos(theta);
     textureCoordinateToUse = vec2(dot(textureCoordinateToUse, vec2(c, -s)), dot(textureCoordinateToUse, vec2(s, c)));
     textureCoordinateToUse += center;
   }
   
   gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
   
 }
 );

@implementation RandomSwirlFilter

@synthesize center = _center;
@synthesize radius = _radius;
@synthesize angle = _angle;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
  if (!(self = [super initWithFragmentShaderFromString:kGPUImageRandomSwirlFragmentShaderString]))
  {
    return nil;
  }
  srand48(arc4random());
  
  radiusUniform = [filterProgram uniformIndex:@"radius"];
  angleUniform = [filterProgram uniformIndex:@"angle"];
  centerUniform = [filterProgram uniformIndex:@"center"];
  
  self.radius = 0.5;
  self.angle = 1.0;
  self.center = CGPointMake(0.5, 0.5);

  [NSTimer scheduledTimerWithTimeInterval:0.3
                                   target:self
                                 selector:@selector(setRandomCenter)
                                 userInfo:nil
                                  repeats:YES];
  return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
  [super setInputRotation:newInputRotation atIndex:textureIndex];
  [self setCenter:self.center];
}

- (void)setRadius:(CGFloat)newValue;
{
  _radius = newValue;
  
  [self setFloat:_radius forUniform:radiusUniform program:filterProgram];
}

- (void)setAngle:(CGFloat)newValue;
{
  _angle = newValue;
  
  [self setFloat:_angle forUniform:angleUniform program:filterProgram];
}

- (void)setCenter:(CGPoint)newValue;
{
  _center = newValue;
  
  CGPoint rotatedPoint = [self rotatedPoint:_center forRotation:inputRotation];
  [self setPoint:rotatedPoint forUniform:centerUniform program:filterProgram];
}

- (void)setRandomCenter;
{
  float newx = _center.x + (drand48() * 2.0 - 1)/10.0;
  newx = MAX(MIN(newx, 1.0), 0.0);
  float newy = _center.y + (drand48() * 2.0 - 1)/10.0;
  newy = MAX(MIN(newy, 1.0), 0.0);
 
  _center = CGPointMake(newx, newy);
  _center = CGPointMake(drand48(), drand48());
  
  CGPoint rotatedPoint = [self rotatedPoint:_center forRotation:inputRotation];
  [self setPoint:rotatedPoint forUniform:centerUniform program:filterProgram];
}

@end
