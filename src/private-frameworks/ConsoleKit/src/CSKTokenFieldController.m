#import <AppKit/AppKit.h>

@interface CSKTokenField : NSTokenField
@end

@implementation CSKTokenField
@end

@interface CSKTokenFieldCell : NSTokenFieldCell
@end

@implementation CSKTokenFieldCell
@end

@interface CSKTokenFieldController : NSObject {
	NSTokenField *_tokenField;
	__weak id _delegate;
	BOOL _isBasicSearchEnabled;
	NSArray *_filters;
}
@property (strong) NSTokenField *tokenField;
@property (weak) id delegate;
@property BOOL isBasicSearchEnabled;
@property (readonly, copy) NSArray *filters;
- (void)updateSearchWithFilters:(NSArray *)filters;
@end

@implementation CSKTokenFieldController

@synthesize tokenField = _tokenField;
@synthesize delegate = _delegate;
@synthesize isBasicSearchEnabled = _isBasicSearchEnabled;
@synthesize filters = _filters;

- (void)updateSearchWithFilters:(NSArray *)filters
{
	_filters = [filters copy];
	self.tokenField.objectValue = _filters;
}

@end
