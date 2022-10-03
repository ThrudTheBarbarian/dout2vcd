//
//  StreamReader.h
//  dout2vcd
//
//  Created by Simon Gornall on 10/2/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StreamReader : NSObject

+ (StreamReader *) StreamReaderWithPath:(NSString *)path;

- (bool) load:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
