#ifndef STUB_WEBKIT_H
#define STUB_WEBKIT_H
#include <AppKit/AppKit.h>
@interface WKWebView : NSView
- (id) initWithFrame: (NSRect)frame configuration: (id)configuration;
- (id) loadRequest: (id)request;
- (id) loadHTMLString: (id)html baseURL: (id)baseURL;
- (id) reload;
- (void) evaluateJavaScript: (id)script completionHandler: (id)completion;
@end
@interface NSObject (Selectors)
- (void) performSelectorOnMainThread: (SEL)s
                           withObject: (id)o
                        waitUntilDone: (BOOL)w;
- (void) callWithObject: (id)o;
@end
#endif

/* The real SDK headers declare these classes and no methods, which is why the
 * guest reaches them through performSelector. The stub says the same, so the
 * stub check cannot accidentally paper over that. */
@interface WKWebViewConfiguration : NSObject
@end

@interface WKUserContentController : NSObject
@end

@interface WKUserScript : NSObject
@end
