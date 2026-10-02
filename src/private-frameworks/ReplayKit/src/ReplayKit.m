/*
	ReplayKit.private

	Apple's private framework behind screen recording and playback. No app links it
	directly, but OpenSwiftUI's rendering internals use its display-list types, so
	SwiftUI cannot link without them.

	RBLayer and RBDevice record drawing into a display list. There is no recording
	context here, so the display list is empty -- the state a renderer already
	handles, and a better answer than inventing rendered geometry the caller would
	then composite.

	Every class is over NSObject: AppKit and QuartzCore are not available to name a
	real superclass from here. The class symbols are emitted either way.
*/

#import <Foundation/Foundation.h>
#import "../include/ReplayKit/ReplayKit.h"

/* ---- Display list ------------------------------------------------------------- */

@implementation RBDisplayList
+ (RBDisplayList*)emptyDisplayList
{
	return [[[RBDisplayList alloc] init] autorelease];
}
- (instancetype)init
{
	if ((self = [super init]))
	{
		_operations = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void)dealloc
{
	[_operations release];
	[super dealloc];
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

@implementation RBDevice
@synthesize width = _width;
@synthesize height = _height;
@synthesize displayList = _displayList;

+ (instancetype)deviceWithWidth:(NSUInteger)width height:(NSUInteger)height
{
	RBDevice* device = [[[self alloc] init] autorelease];
	device->_width = width;
	device->_height = height;
	device->_displayList = [[RBDisplayList emptyDisplayList] retain];
	return device;
}
- (void)dealloc
{
	[_displayList release];
	[super dealloc];
}
- (void)flush
{
}
@end

/* ---- Layer ------------------------------------------------------------------- */

@implementation RBLayer
@synthesize device = _device;

- (instancetype)initWithDevice:(RBDevice*)device
{
	if ((self = [super init]))
	{
		_device = [device retain];
	}
	return self;
}
- (void)dealloc
{
	[_device release];
	[super dealloc];
}
- (void)display
{
}
@end

/* ---- Animation --------------------------------------------------------------- */

@implementation RBAnimation
@synthesize name = _name;
@synthesize duration = _duration;

+ (instancetype)animationWithName:(NSString*)name duration:(double)duration
{
	RBAnimation* animation = [[[self alloc] init] autorelease];
	animation->_name = [name copy];
	animation->_duration = duration;
	return animation;
}
- (void)dealloc
{
	[_name release];
	[super dealloc];
}
@end

/* ---- Animator ---------------------------------------------------------------- */

@implementation RBSymbolAnimator
- (BOOL)advanceBy:(double)interval
{
	(void)interval;
	if (_didAdvance)
	{
		return NO;
	}
	_didAdvance = YES;
	return YES;
}
@end
