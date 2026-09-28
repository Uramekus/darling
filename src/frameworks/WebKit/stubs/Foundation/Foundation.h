/* Minimal Foundation surface, only what WKWebView.m touches. Exists so the
 * guest file can be syntax-checked off-target. Deliberately NOT a substitute
 * for the real headers: it proves my code parses and that every selector and
 * ivar I use is spelled consistently, not that it links against Darling. */
#ifndef STUB_FOUNDATION_H
#define STUB_FOUNDATION_H
#include <stdint.h>
#include <stddef.h>
typedef unsigned long NSUInteger;
typedef long NSInteger;
typedef double CGFloat;
typedef struct { CGFloat x, y; } NSPoint;
typedef struct { CGFloat width, height; } NSSize;
typedef struct { NSPoint origin; NSSize size; } NSRect;
typedef int BOOL;
#define YES 1
#define NO 0
#define NS_ENUM(_type, _name) _type _name; enum
/* Enough libdispatch for the completion-handler pattern; the real SDK provides
 * the full header. */
typedef void (^dispatch_block_t)(void);
struct dwb_dispatch_queue;
typedef struct dwb_dispatch_queue *dispatch_queue_t;
extern dispatch_queue_t dispatch_get_main_queue(void);
extern void dispatch_async(dispatch_queue_t q, dispatch_block_t block);

#define nil ((id)0)
#define NULLPTR ((void *)0)
extern void NSLog(id fmt, ...);
@class NSString, NSData, NSURL, NSURLRequest, NSError, NSDictionary, NSView;

#define NSLocalizedDescriptionKey @"NSLocalizedDescription"

@protocol NSObject
- (id) init;
- (void) dealloc;
- (id) retain;
- (void) release;
- (id) autorelease;
- (id) copy;
- (BOOL) respondsToSelector: (SEL)s;
- (id) performSelector: (SEL)s;
@end
@interface NSObject <NSObject>
+ (id) alloc; + (id) new; + (Class) class;
@end

@interface NSDictionary : NSObject
+ (NSDictionary *) dictionaryWithObject: (id)obj forKey: (id)key;
- (id) objectForKey: (id)key;
@end

@interface NSError : NSObject
+ (NSError *) errorWithDomain: (NSString *)domain
                          code: (int)code
                      userInfo: (NSDictionary *)userInfo;
@end
@interface NSArray : NSObject
- (NSUInteger) count;
- (id) objectAtIndex: (NSUInteger)i;
@end
@interface NSMutableDictionary : NSObject
- (id) objectForKey: (id)key;
- (void) setObject: (id)obj forKey: (id)key;
- (void) removeObjectForKey: (id)key;
@end

@interface NSMutableArray : NSArray
- (id) init;
- (void) addObject: (id)o;
- (void) removeObject: (id)o;
- (void) removeAllObjects;
- (BOOL) containsObject: (id)o;
@end
@interface NSString : NSObject
+ (id) stringWithUTF8String: (const char *)s;
+ (id) stringWithFormat: (id)fmt, ...;
- (const char *) UTF8String;
- (id) dataUsingEncoding: (NSUInteger)enc;
- (NSUInteger) length;
- (id) initWithFormat: (id)fmt, ...;
@end
@interface NSData : NSObject
- (id) base64EncodedStringWithOptions: (NSUInteger)opts;
@end
@interface NSURL : NSObject
+ (id) URLWithString: (NSString *)s;
- (NSString *) absoluteString;
@end
@interface NSURLRequest : NSObject
+ (id) requestWithURL: (NSURL *)url;
- (NSURL *) URL;
@end
extern const NSUInteger NSUTF8StringEncoding;
#endif
