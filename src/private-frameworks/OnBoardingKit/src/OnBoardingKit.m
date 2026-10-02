/*
	OnBoardingKit.private

	Apple's private framework behind the onboarding and privacy-consent flow: the
	welcome screens an app shows on first run, and the privacy presenter that links
	to the App Store and other services. Fifteen of the local apps link it, the
	widest-reaching gap in the private-framework tier.

	The controllers are real NSViewControllers with no view content, which is a
	state every caller already handles: a flow with nothing to show completes. The
	privacy presenter reports no services, because there is no App Store here to
	link to.

	Every class is declared over NSObject rather than over its real AppKit base,
	because AppKit does not exist on this system.
*/

#import <Foundation/Foundation.h>
#import "../include/OnBoardingKit/OnBoardingKit.h"

/* ---- Privacy service identifiers --------------------------------------------- */

NSString* const OBPrivacyAppStoreIdentifier        = @"com.apple.appstore";
NSString* const OBPrivacyAppleMusicIdentifier      = @"com.apple.AppleMusic";
NSString* const OBPrivacyAppleArcadeIdentifier     = @"com.apple.Arcade";
NSString* const OBPrivacyTVAppIdentifier           = @"com.apple.TV";
NSString* const OBPrivacyiTunesStoreIdentifier     = @"com.apple.iTunesStore";

/* ---- OBBundle ---------------------------------------------------------------- */

@implementation OBBundle
+ (NSArray*)privacyServiceIdentifiers
{
	return [NSArray array];
}
@end

/* ---- Template views ---------------------------------------------------------- */

@implementation OBTemplateView
@synthesize templateIdentifier;
@end

@implementation OBTemplatePartBulletList
- (instancetype)init
{
	if ((self = [super init]))
	{
		_bullets = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void)dealloc
{
	[_bullets release];
	[super dealloc];
}
- (void)addBullet:(NSString*)text
{
	if (text)
	{
		[_bullets addObject:text];
	}
}
- (void)removeAllBullets
{
	[_bullets removeAllObjects];
}
- (NSUInteger)bulletCount
{
	return [_bullets count];
}
@end

/* ---- Buttons ----------------------------------------------------------------- */

@implementation OBBoldTrayButton
- (void)setTitle:(NSString*)title
{
	[_title release];
	_title = [title copy];
}
- (void)dealloc
{
	[_title release];
	[super dealloc];
}
@end

@implementation OBLinkTrayButton
@end

@implementation OBBulletedListItemLinkButton
- (void)setDestinationURL:(NSURL*)url
{
	[_url release];
	_url = [url copy];
}
- (void)dealloc
{
	[_url release];
	[super dealloc];
}
@end

/* ---- Controllers -------------------------------------------------------------- */

@implementation OBTemplateContainerViewController
- (void)setBullets:(NSArray*)bullets
{
	(void)bullets;
}
@end

@implementation OBTableWelcomeController
@synthesize title;
@synthesize body;
@end

@implementation OBWelcomeController
- (void)advance
{
}
- (void)finish
{
}
@end

@implementation OBNavigationController
- (instancetype)init
{
	if ((self = [super init]))
	{
		_stack = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void)dealloc
{
	[_stack release];
	[super dealloc];
}
- (void)pushViewController:(id)controller
{
	if (controller)
	{
		[_stack addObject:controller];
	}
}
- (void)popViewController
{
	if ([_stack count] > 0)
	{
		[_stack removeLastObject];
	}
}
- (NSUInteger)viewControllerCount
{
	return [_stack count];
}
@end

/* ---- Privacy flow ------------------------------------------------------------- */

@implementation OBPrivacySplashController
- (void)showPrivacySplash
{
}
@end

@implementation OBPrivacyLinkController
- (void)openServiceWithIdentifier:(NSString*)identifier
{
	(void)identifier;
}
@end

@implementation OBPrivacyPresenter
+ (instancetype)presenterForBundleIdentifier:(NSString*)bundleIdentifier
{
	OBPrivacyPresenter* presenter = [[[self alloc] init] autorelease];
	presenter->_bundleIdentifier = [bundleIdentifier copy];
	return presenter;
}
- (void)dealloc
{
	[_bundleIdentifier release];
	[super dealloc];
}
- (NSArray*)servicesRequiringConsent
{
	return [NSArray array];
}
- (BOOL)presentConsentForService:(NSString*)identifier error:(NSError**)error
{
	(void)identifier;
	if (error)
	{
		*error = nil;
	}
	return YES;
}
@end

@implementation OBPrivacyFlow
+ (instancetype)flowWithBundleIdentifier:(NSString*)bundleIdentifier
{
	OBPrivacyFlow* flow = [[[self alloc] init] autorelease];
	(void)bundleIdentifier;
	return flow;
}
- (BOOL)run:(NSError**)error
{
	if (error)
	{
		*error = nil;
	}
	return YES;
}
@end
