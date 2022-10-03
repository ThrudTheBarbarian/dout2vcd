//
//  NSString+NSString_Binary.h
//  dout2vcd
//
//  Created by Simon Gornall on 10/2/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (NSString_Binary)

+ (NSString *)binaryStringRepresentationOfInt:(long)value;
+ (NSString *)binaryStringRepresentationOfInt:(long)value
							   numberOfDigits:(unsigned int)length
							      chunkLength:(unsigned int)chunkLength;

@end

NS_ASSUME_NONNULL_END
