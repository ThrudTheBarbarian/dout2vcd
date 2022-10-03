//
//  NSString+NSString_Binary.m
//  dout2vcd
//
//  Created by Simon Gornall on 10/2/22.
//

#import "NSString+Binary.h"

@implementation NSString (Binary)

+ (NSString *)binaryStringRepresentationOfInt:(unsigned long)value
	{
    unsigned int numberOfDigits 	= 8;
    return [self binaryStringRepresentationOfInt:value
								  numberOfDigits:numberOfDigits
								     chunkLength:65];
	}

+ (NSString *)binaryStringRepresentationOfInt:(long)value
							   numberOfDigits:(unsigned int)length
								  chunkLength:(unsigned int)chunkLength
	{
    NSMutableString *string = [NSMutableString new];

    for(int i = 0; i < length; i ++)
		{
        NSString *divider 	= i % chunkLength == chunkLength-1 ? @" " : @"";
        NSString *part 		= [NSString stringWithFormat:@"%@%i",
								divider,
								value & (1 << i) ? 1 : 0];
        [string insertString:part atIndex:0];
		}

    return string;
	}

@end
