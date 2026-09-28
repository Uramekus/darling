/*
	ReplayKit.private

	Apple's private framework behind screen recording and playback. No app here
	links it directly, but OpenSwiftUI's rendering internals use its display-list
	types, so SwiftUI cannot link without them: CAHostingLayerPlatformDefinition and
	RenderBoxView reference RBDevice and RBLayer, DisplayList and Image reference
	RBAnimation, GraphicsImage references RBSymbolAnimator.

	RBLayer and RBDevice are the platform pair: a layer that draws into a device, with
	the display list the drawing is recorded into. Recording a display list needs a
	recording context, and there is no recording here, so the display list is empty.
	An empty display list is the state a renderer already handles -- it draws nothing
	and the caller composites the result -- whereas inventing rendered geometry would
	be worse than drawing nothing, because the caller would composite a picture of
	something that was never captured.

	RBAnimation is a named animation curve. Nothing is animating without a recording
	to animate into, so the duration is zero: a zero-duration animation is complete
	on its first frame, which is the state a caller has to handle anyway when an
	animation is skipped.

	RBSymbolAnimator advances symbol animations over time. With no time source and
	nothing to animate, it reports that it has finished rather than looping.

	Every class is over NSObject: AppKit and QuartzCore are not available to name a
	real superclass from here, and CALayer in particular cannot be linked against on
	this system. The class symbols are what the linker needs, and they are emitted
	identically either way.
*/

#import <Foundation/Foundation.h>

/* ---- Display list ------------------------------------------------------------- */

/* The recorded drawing operations for a device. */
@interface RBDisplayList : NSObject

/* An empty display list: nothing was recorded, so there is nothing to replay. */
+ (RBDisplayList*)emptyDisplayList;

/* Append the current contents of a view. No recording context exists here, so this
   records nothing and the list stays empty. */
- (void)appendView:(id)view;

- (NSUInteger)operationCount;

@end

@implementation RBDisplayList
{
	NSMutableArray* _operations;
}
+ (RBDisplayList*)emptyDisplayList
{
	return [[RBDisplayList alloc] init];
}
- (instancetype)init
{
	if ((self = [super init]))
	{
		_operations = [NSMutableArray array];
	}
	return self;
}
- (void)appendView:(id)view
{
	(void)view;
}
- (NSUInteger)operationCount
{
	return [_operations count];
}
@end

/* ---- Device ------------------------------------------------------------------ */

/* A rendering destination: width, height, and a display list to draw into. */
@interface RBDevice : NSObject

+ (instancetype)deviceWithWidth:(NSUInteger)width height:(NSUInteger)height;

@property (readonly) NSUInteger width;
@property (readonly) NSUInteger height;
@property (readonly, strong) RBDisplayList* displayList;

/* Flushes the device's drawing. Nothing was recorded, so there is nothing to
   submit and this is a no-op rather than an error. */
- (void)flush;

@end

@implementation RBDevice
{
	NSUInteger _width;
	NSUInteger _height;
	RBDisplayList* _displayList;
}
+ (instancetype)deviceWithWidth:(NSUInteger)width height:(NSUInteger)height
{
	RBDevice* device = [[self alloc] init];
	device->_width = width;
	device->_height = height;
	device->_displayList = [RBDisplayList emptyDisplayList];
	return device;
}
- (NSUInteger)width
{
	return _width;
}
- (NSUInteger)height
{
	return _height;
}
- (RBDisplayList*)displayList
{
	return _displayList;
}
- (void)flush
{
}
@end

/* ---- Layer ------------------------------------------------------------------- */

/* A layer that records into a device's display list. */
@interface RBLayer : NSObject

- (instancetype)initWithDevice:(RBDevice*)device;

/* Asks the layer to record itself into its device's display list. Without a
   recording context this records nothing, which leaves the display list empty. */
- (void)display;

@property (readonly, strong) RBDevice* device;

@end

@implementation RBLayer
{
	RBDevice* _device;
}
- (instancetype)initWithDevice:(RBDevice*)device
{
	if ((self = [super init]))
	{
		_device = device;
	}
	return self;
}
- (RBDevice*)device
{
	return _device;
}
- (void)display
{
}
@end

/* ---- Animation ---------------------------------------------------------------- */

/* A named animation curve applied to a recording. */
@interface RBAnimation : NSObject

+ (instancetype)animationWithName:(NSString*)name duration:(double)duration;

@property (readonly, copy) NSString* name;
@property (readonly) double duration;

@end

@implementation RBAnimation
{
	NSString* _name;
	double _duration;
}
+ (instancetype)animationWithName:(NSString*)name duration:(double)duration
{
	RBAnimation* animation = [[self alloc] init];
	animation->_name = [name copy];
	animation->_duration = duration;
	return animation;
}
- (NSString*)name
{
	return _name;
}
- (double)duration
{
	return _duration;
}
@end

/* Advances symbol animations. */
@interface RBSymbolAnimator : NSObject

/* Advances by a time interval. Reports YES while more frames remain, so a caller
   driving this loop terminates: with no recorded animation there are no frames
   left after the first step. */
- (BOOL)advanceBy:(double)interval;

@end

@implementation RBSymbolAnimator
- (BOOL)advanceBy:(double)interval
{
	(void)interval;
	return NO;
}
@end
