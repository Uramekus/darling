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

#ifndef REPLAYKIT_H
#define REPLAYKIT_H

#import <Foundation/Foundation.h>

@class RBDevice;
@class RBDisplayList;

@interface RBDisplayList : NSObject

/* An empty display list: nothing was recorded, so there is nothing to replay. */
+ (RBDisplayList*)emptyDisplayList;

/* Append the current contents of a view. No recording context exists here, so this
   records nothing and the list stays empty. */
- (void)appendView:(id)view;

- (NSUInteger)operationCount;

@end

@interface RBDevice : NSObject

+ (instancetype)deviceWithWidth:(NSUInteger)width height:(NSUInteger)height;

@property (readonly) NSUInteger width;
@property (readonly) NSUInteger height;
@property (readonly, strong) RBDisplayList* displayList;

/* Flushes the device's drawing. Nothing was recorded, so there is nothing to
   submit and this is a no-op rather than an error. */
- (void)flush;

@end

@interface RBLayer : NSObject

- (instancetype)initWithDevice:(RBDevice*)device;

/* Asks the layer to record itself into its device's display list. Without a
   recording context this records nothing, which leaves the display list empty. */
- (void)display;

@property (readonly, strong) RBDevice* device;

@end

@interface RBAnimation : NSObject

+ (instancetype)animationWithName:(NSString*)name duration:(double)duration;

@property (readonly, copy) NSString* name;
@property (readonly) double duration;

@end

@interface RBSymbolAnimator : NSObject

/* Advances by a time interval. Reports YES while more frames remain, so a caller
   driving this loop terminates: with no recorded animation there are no frames
   left after the first step. */
- (BOOL)advanceBy:(double)interval;

@end

#endif
