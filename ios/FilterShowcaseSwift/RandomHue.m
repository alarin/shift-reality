
#import "RandomHue.h"

// Adapted from http://stackoverflow.com/questions/9234724/how-to-change-hue-of-a-texture-with-glsl - see for code and discussion

NSString *const kGPUImageRandomHueFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform mediump float hueAdjust;
 const highp  vec4  kRGBToYPrime = vec4 (0.299, 0.587, 0.114, 0.0);
 const highp  vec4  kRGBToI     = vec4 (0.595716, -0.274453, -0.321263, 0.0);
 const highp  vec4  kRGBToQ     = vec4 (0.211456, -0.522591, 0.31135, 0.0);
 
 const highp  vec4  kYIQToR   = vec4 (1.0, 0.9563, 0.6210, 0.0);
 const highp  vec4  kYIQToG   = vec4 (1.0, -0.2721, -0.6474, 0.0);
 const highp  vec4  kYIQToB   = vec4 (1.0, -1.1070, 1.7046, 0.0);
 

 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 
 float rand(vec2 co){
   return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
 }
 
 float random( vec2 p ) // Version 2
{
  // e^pi (Gelfond's constant)
  // 2^sqrt(2) (Gelfond–Schneider constant)
  vec2 r = vec2( 23.14069263277926, 2.665144142690225 );
  //return fract( cos( mod( 12345678., 256. * dot(p,r) ) ) ); // ver1
  return fract(cos(dot(p,r)) * 123456.); // ver2
}
 
 void main ()
 {
   // Sample the input pixel
   highp vec4 color   = texture2D(inputImageTexture, textureCoordinate);
   
   // Convert to YIQ
   highp float   YPrime  = dot (color, kRGBToYPrime);
   highp float   I      = dot (color, kRGBToI);
   highp float   Q      = dot (color, kRGBToQ);
   
   // Calculate the hue and chroma
   highp float   hue     = atan (Q, I);
   highp float   chroma  = sqrt (I * I + Q * Q);
   
   // Make the user's adjustments
//   hue += (-hueAdjust); //why negative rotation?
   highp float rhue = rand(textureCoordinate);
   
//   float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
//   float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
//   float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
//   float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
//   float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
//   float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
//   float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
//   float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
//   
//   float verticalDerivative = -topLeftIntensity - topIntensity - topRightIntensity + bottomLeftIntensity + bottomIntensity + bottomRightIntensity;
//   float horizontalDerivative = -bottomLeftIntensity - leftIntensity - topLeftIntensity + bottomRightIntensity + rightIntensity + topRightIntensity;
 
   hue += textureCoordinate[0] * 360.0 * M_PI/180.0;
   
//   hue += (-hueAdjust);
   
   // Convert back to YIQ
   Q = chroma * sin (hue);
   I = chroma * cos (hue);
   
   // Convert back to RGB
   highp vec4    yIQ   = vec4 (YPrime, I, Q, 0.0);
   color.r = dot (yIQ, kYIQToR);
   color.g = dot (yIQ, kYIQToG);
   color.b = dot (yIQ, kYIQToB);
   
   // Save the result
   gl_FragColor = color;
 }
 );

@implementation RandomHue
@synthesize hue;

- (id)init
{
  if(! (self = [super initWithFragmentShaderFromString:kGPUImageRandomHueFragmentShaderString]) )
  {
    return nil;
  }
  
  hueAdjustUniform = [filterProgram uniformIndex:@"hueAdjust"];
  self.hue = 90;
  
  return self;
}

- (void)setHue:(CGFloat)newHue
{
  // Convert degrees to radians for hue rotation
  hue = fmodf(newHue, 360.0) * M_PI/180;
  [self setFloat:hue forUniform:hueAdjustUniform program:filterProgram];
}

@end
