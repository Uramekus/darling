/*
	QuickLookUI.private

	Apple's private framework behind the Quick Look preview UI. Nine of the local
	apps link it, binding seven classes.

	Declared so the classes can be compiled, and so callers building against this
	framework see the same interfaces. The apps reach these classes through the
	Objective-C runtime rather than the linker for the class objects themselves, so
	the header is here for the build.

	Subclass fidelity is limited by the headers on this system. NSView.h, NSPanel.h
	and NSFont.h all pull in ApplicationServices, which has no headers here, so
	QLPreviewView and QLPreviewPanel are declared over NSObject rather than NSView
	and NSPanel. The class symbols are emitted either way. Every app linking this
	framework is itself blocked on AppKit, so the superclass only becomes
	observable once AppKit exists; at that point these two should move onto their
	real bases.
*/

#import <Foundation/Foundation.h>
#import "../include/QuickLookUI/QuickLookUI.h"
#include <unistd.h>

/* ---- QLPreviewDocument -------------------------------------------------------- */

@implementation QLPreviewDocument
@synthesize fileURL = _fileURL;
- (instancetype)initWithFileURL:(NSURL*)url
{
	if ((self = [super init]))
	{
		_fileURL = [url copy];
	}
	return self;
}
- (void)dealloc
{
	[_fileURL release];
	[super dealloc];
}

/* Whether the URL names something this process can read, which is the question
   being asked. access() answers exactly that and needs no Foundation class, and
   NSFileManager is not built on this system yet. */
- (BOOL)isReadable
{
	if (_fileURL == nil)
	{
		return NO;
	}
	return access([[_fileURL path] fileSystemRepresentation], R_OK) == 0;
}
@end

/* ---- QLPreviewView ----------------------------------------------------------- */

@implementation QLPreviewView
- (void)setPreviewDocument:(QLPreviewDocument*)document
{
	if (_document != document)
	{
		[_document release];
		_document = [document retain];
	}
}
- (QLPreviewDocument*)previewDocument
{
	return _document;
}
- (void)dealloc
{
	[_document release];
	[super dealloc];
}
@end

/* ---- QLPreviewPanel ---------------------------------------------------------- */

@implementation QLPreviewPanel
+ (QLPreviewPanel*)sharedPreviewPanel
{
	static QLPreviewPanel* instance;
	if (instance == nil)
	{
		instance = [[QLPreviewPanel alloc] init];
	}
	return instance;
}
- (void)makeKeyAndOrderFront:(id)sender
{
	(void)sender;
}
- (void)orderOut:(id)sender
{
	(void)sender;
}
@end

/* ---- The seamless-preview family --------------------------------------------- */

@implementation QLSeamlessDocumentOpener
+ (id)openerForDocument:(QLPreviewDocument*)document
{
	QLSeamlessDocumentOpener* opener = [[[self alloc] init] autorelease];
	opener->_document = [document retain];
	return opener;
}
- (void)dealloc
{
	[_document release];
	[super dealloc];
}

/* No document window server to present into, so the open does not happen and the
   error says why. A caller already handles a failed open by falling back. */
- (BOOL)openDocument:(NSError**)error
{
	if (error)
	{
		*error = [NSError errorWithDomain:@"QLSeamlessPreviewErrorDomain"
		                             code:1
		                         userInfo:@{NSLocalizedDescriptionKey:
		                                        @"Seamless preview is not available"}];
	}
	return NO;
}
@end

@implementation QLSeamlessDocumentCloser
+ (id)closerForDocument:(QLPreviewDocument*)document
{
	QLSeamlessDocumentCloser* closer = [[[self alloc] init] autorelease];
	(void)document;
	return closer;
}
- (BOOL)closeDocument:(NSError**)error
{
	if (error)
	{
		*error = nil;
	}
	return YES;
}
@end

@implementation QLSeamlessOpener
@end

@implementation QLWarpingWindowEffect
@end
