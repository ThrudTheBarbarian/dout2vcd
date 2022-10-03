//
//  Variable.h
//  dout2vcd
//
//  Created by Simon Gornall on 10/2/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Variable : NSObject

typedef enum
	{
	UNKNOWN = 0,
	DECIMAL,
	HEX,
	TIME
	} Format;
	

+ (Variable *) variableWithName:(NSString *)name
						  width:(int)width
						  token:(char)token;

- (NSString *) vcdFormat;

@property (assign, nonatomic) int 		width;		// Bits to hold this var
@property (assign, nonatomic) char		token;		// Identifier in the file
@property (copy, nonatomic) NSString *	name;		// Name of the variable
@property (assign, nonatomic) uint64_t 	value;		// Last value
@property (assign, nonatomic) Format 	format;		// Last value
@property (assign, nonatomic) bool 		record;		// Do we record this var ?
@property (assign, nonatomic) bool		isDirty;	// Needs output
@end
						  
NS_ASSUME_NONNULL_END
