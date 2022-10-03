//
//  main.m
//  dout2vcd
//
//  Created by Simon Gornall on 10/2/22.
//

#import <Foundation/Foundation.h>
#import "StreamReader.h"

int main(int argc, const char * argv[])
	{
	@autoreleasepool
		{
	    if (argc != 2)
			{
			fprintf(stderr, "Usage: dout2vcd <filename>\n");
			exit(0);
			}
		
		NSString *path = [NSString stringWithUTF8String:argv[1]];
		StreamReader *sr = [StreamReader StreamReaderWithPath:path];
		
		}
	return 0;
	}
