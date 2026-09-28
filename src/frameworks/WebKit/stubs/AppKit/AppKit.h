#ifndef STUB_APPKIT_H
#define STUB_APPKIT_H
#include <Foundation/Foundation.h>
@interface NSString (AppKitConst)
@end
extern NSString *NSDeviceRGBColorSpace;
@interface NSTimer : NSObject
+ (NSTimer *) scheduledTimerWithTimeInterval: (double)seconds
                                     target: (id)target
                                   selector: (SEL)sel
                                   userInfo: (id)info
                                    repeats: (BOOL)repeats;
- (void) invalidate;
@end

@interface NSView : NSObject
- (id) initWithFrame: (NSRect)frame;
- (void) setAutoresizesSubviews: (BOOL)v;
- (void) setFrame: (NSRect)f;
- (NSRect) frame;
- (NSRect) bounds;
- (BOOL) lockFocusIfCanDraw;
- (void) unlockFocus;
@end
@class NSImage;

static inline NSRect NSMakeRect(double x, double y, double w, double h) {
	NSRect r; r.origin.x = x; r.origin.y = y; r.size.width = w; r.size.height = h; return r;
}
/* Darling keeps the older compositing spelling; Apple's is
 * NSCompositingOperationSourceOver. */
#define NSCompositeSourceOver 0

/* A rep is a kind of image, as in Cocoa. */
@interface NSImageRep : NSObject
@end

@interface NSImage : NSObject
- (void) drawInRect: (NSRect)rect
           fromRect: (NSRect)source
          operation: (int)operation
           fraction: (double)fraction;
@end

@interface NSBitmapImageRep : NSImageRep
- (id) initWithBitmapDataPlanes: (unsigned char **)planes /* pixelsHigh: below, matching Darling - Apple's own selector is misspelled bitsHigh: */
                   pixelsWide: (NSUInteger)w
                   bitsHigh: (NSUInteger)h
                bitsPerSample: (NSUInteger)bps
              samplesPerPixel: (NSUInteger)spp
                     hasAlpha: (BOOL)alpha
                     isPlanar: (BOOL)planar
               colorSpaceName: (NSString *)cs
                  bytesPerRow: (NSUInteger)stride
                 bitsPerPixel: (NSUInteger)bpp;
- (void) drawInNSRect: (NSRect)r;
@end
#endif
