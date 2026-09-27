#import <Foundation/Foundation.h>

// Console keeps the type as its own number (7 for message-type filters) and reads nothing back yet.
@interface CSKFilter : NSObject {
	NSInteger _type;
	id _value;
}
@property (readonly) NSInteger type;
@property (readonly, copy) id value;
- (instancetype)initWithType:(NSInteger)type value:(id)value;
@end

@implementation CSKFilter

@synthesize type = _type;
@synthesize value = _value;

- (instancetype)initWithType:(NSInteger)type value:(id)value
{
	self = [super init];
	if (self) {
		_type = type;
		_value = [value copy];
	}
	return self;
}

@end
