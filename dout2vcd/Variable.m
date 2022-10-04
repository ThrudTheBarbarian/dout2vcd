//
//  Variable.m
//  dout2vcd
//
//  Created by Simon Gornall on 10/2/22.
//

#import "NSString+Binary.h"

#import "Variable.h"

@implementation Variable

+ (Variable *) variableWithName:(NSString *)name
						  width:(int)width
						  token:(char)token
	{
	Variable *v = [Variable new];
	[v setName:name];
	[v setWidth:width];
	[v setToken:token];
	[v setValue:0];
	[v setFormat:UNKNOWN];
	[v setRecord:true];
	
	return v;
	}

- (NSString *) vcdFormat
	{
	NSString *fmt = nil;
	if (_width == 1)
		fmt = [NSString stringWithFormat:@"%c%c",
				((_value == 1) ? '1' : '0'), _token];
	else
		{
		NSMutableString *val = [NSMutableString new];
		[val appendFormat:@"b%@ %c",
			[NSString binaryStringRepresentationOfInt:_value
									   numberOfDigits:_width
									      chunkLength:127],
			_token];
		fmt = val;
		}
	return fmt;
	}

- (NSString *) description
	{
	return [NSString stringWithFormat:@"Variable: %@ %llx (%d) : '%c' %@",
					_name,
					_value,
					_width,
					_token,
					(_record ? @"" : @"(ignored)")];
	}
@end
