//
//  StreamReader.m
//  dout2vcd
//
//  Created by Simon Gornall on 10/2/22.
//

#define VERSION_STR		"DOUT -> VCD generator tool v0.1"
#define STATE_NUMBER	"Time"

#import "NSString+Binary.h"
#import "StreamReader.h"
#import "Variable.h"

@interface StreamReader()
@property (assign, nonatomic) FILE * fp;
@property (assign, nonatomic) FILE * ofp;
@property (strong, nonatomic) NSMutableArray *vars;

- (bool) _parseHeader;
- (bool) _writeVCDPreamble:(NSString *)path;
- (bool) _streamData;

@end

@implementation StreamReader
/****************************************************************************\
|* Convenience method
\****************************************************************************/
+ (StreamReader *) StreamReaderWithPath:(NSString *)path
	{
	StreamReader *sr = [StreamReader new];
	if ([sr load:path])
		return sr;
	return nil;
	}

/****************************************************************************\
|* Load in the stream and start to parse it to stdout
\****************************************************************************/
- (bool) load:(NSString *)path
	{
	const char *filepath = [path fileSystemRepresentation];
	
	_ofp = NULL;
	_fp = fopen(filepath, "r");
	if (_fp == NULL)
		{
		fprintf(stderr, "Cannot read file '%s'\n", filepath);
		return false;
		}
	
	_vars = [NSMutableArray array];
	bool ok = [self _parseHeader];
	if (ok)
		ok = [self _writeVCDPreamble:path];
	if (ok)
		ok = [self _streamData];
		
	fclose(_fp);
	if (_ofp != NULL)
		fclose(_ofp);
	return true;
	}

/****************************************************************************\
|* Parse the headers
\****************************************************************************/
- (bool) _parseHeader
	{
	char buf[2048];
	
	fprintf(stderr, "Starting\n");
	fprintf(stderr, " - Scanning for header\n");
	
	/************************************************************************\
	|* Look for the header start
	\************************************************************************/
	bool foundHeaderStart = false;
	while (!foundHeaderStart)
		{
		if (fgets(buf, 2048, _fp) == NULL)
			{
			fprintf(stderr, " * Failed to find header\n");
			return false;
			}
		if (strncasecmp(buf, "16505_Data_Header_Begin", 23) == 0)
			foundHeaderStart = true;
		}

	/************************************************************************\
	|* Until we get to header-end, parse out variables
	\************************************************************************/
	char token = '#';
	NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	while (true)
		{
		/*******************************************************************\
		|* Read the name
		\*********************************************************************/
		if (fgets(buf, 2048, _fp) == NULL)
			{
			fprintf(stderr, " * Failed to parse header name\n");
			return false;
			}
			
		if (strncasecmp(buf, "16505_Data_Header_End", 21) == 0)
			break;
			
		NSString *line 	= [NSString stringWithUTF8String:buf];
		line 		    = [line stringByTrimmingCharactersInSet:cs];
		NSArray *parts 	= [line componentsSeparatedByString:@":"];
		NSString *name	= [parts lastObject];
		
		/********************************************************************\
		|* Read the format
		\********************************************************************/
		Format fmt = UNKNOWN;
		
		if (fgets(buf, 2048, _fp) == NULL)
			{
			fprintf(stderr, " * Failed to parse header format\n");
			return false;
			}
		if (strncasecmp(buf, "hex", 3) == 0)
			fmt = HEX;
		else if (strncasecmp(buf, "decimal", 7) == 0)
			fmt = DECIMAL;
		else if (strncasecmp(buf, "Absolute-picoseconds", 20) == 0)
			fmt = TIME;
		else
			{
			fprintf(stderr, " * Found unknown format %s\n", buf);
			return false;
			}
		
		/********************************************************************\
		|* Read the width
		\********************************************************************/
		int width = 0;
		
		if (fgets(buf, 2048, _fp) == NULL)
			{
			fprintf(stderr, " * Failed to parse header width\n");
			return false;
			}
		sscanf(buf, "%d", &width);
		
		/********************************************************************\
		|* Create the variable
		\********************************************************************/
		Variable *v = [Variable variableWithName:name width:width token:token];
		token ++;
		bool doRecord = true;
		if ([name hasSuffix:@"_TZ"])
			doRecord = false;
		if ((fmt != DECIMAL) && (fmt != HEX))
			doRecord = false;
		if ([name isEqualToString:@"State Number"])
			doRecord = false;
		
		[v setFormat:fmt];
		[v setRecord:doRecord];
		[_vars addObject:v];
		
		if ([v record])
			fprintf(stderr, " - Registering var '%s'\n", [[v name] UTF8String]);
		}

	return true;
	}

/****************************************************************************\
|* Open the file for the VCD data
\****************************************************************************/
- (bool) _writeVCDPreamble:(NSString *)path
	{
	path 				= [path stringByAppendingString:@".vcd"];
	const char *vcdpath = [path fileSystemRepresentation];
	
	_ofp = fopen(vcdpath, "w");
	if (_ofp == NULL)
		{
		fprintf(stderr, " * Failed to open VCD path %s\n", vcdpath);
		return false;
		}
	
	const char *now = [[[NSDate date] description] UTF8String];
	fprintf(_ofp, "$date\n%s\n$end\n", now);
	fprintf(_ofp, "$version\n%s\n$end\n", VERSION_STR);
	fprintf(_ofp, "$timescale 1ps $end\n");
	fprintf(_ofp, "$scope module logic $end\n");
	
	for (Variable *v in _vars)
		{
		if ([v record])
			{
			NSString *name = [[v name] stringByReplacingOccurrencesOfString:@" "
			 withString:@"_"];
			
			fprintf(_ofp, "$var wire %d %c %s $end\n",
					[v width], [v token], [name UTF8String]);
			}
		}
	fprintf(_ofp, "$upscope $end\n");
	fprintf(_ofp, "$enddefinitions $end\n");
	fprintf(_ofp, "$dumpvars\n");
	
	for (Variable *v in _vars)
		{
		if ([v record])
			{
			if ([v width] == 1)
				fprintf(_ofp, "x%c\n", [v token]);
			else
				{
				fprintf(_ofp, "b");
				for (int i=0; i<[v width]; i++)
					fprintf(_ofp, "x");
				fprintf(_ofp, " %c\n", [v token]);
				}
			}
		}
	fprintf(_ofp, "$end\n");
	return true;
	}

/****************************************************************************\
|* Start streaming data from the DOUT file to the VCD file
\****************************************************************************/
- (bool) _streamData
	{
	char buf[2048];
	fprintf(stderr, " - Streaming data to VCD file\n");
	
	long long startTime 	= 0;
	bool firstRecord		= true;

	NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSCharacterSet *ws = [NSCharacterSet whitespaceCharacterSet];

	/************************************************************************\
	|* Find the index of the State Number field
	\************************************************************************/
	int timeIdx = 0;
	for (Variable *v in _vars)
		{
		if ([v format] == TIME)
			break;
		timeIdx ++;
		}

	/************************************************************************\
	|* Loop over all the data
	\************************************************************************/
	while (true)
		{
		long long currentTime 	= 0;
		bool changes			= firstRecord;
		
		if (fgets(buf, 2048, _fp) == NULL)
			{
			if (!feof(_fp))
				{
				fprintf(stderr, " * Failed to read in streaming data\n");
				return false;
				}
			fprintf(stderr, " - Completed streaming data\n");
			return true;
			}
		
		/********************************************************************\
		|* Determine any new state
		\********************************************************************/
		NSString *line 	= [NSString stringWithUTF8String:buf];
		line 			= [line stringByTrimmingCharactersInSet:cs];
		NSArray *items	= [line componentsSeparatedByCharactersInSet:ws];

		/********************************************************************\
		|* If this is the first time around, get the starting time directly
		\********************************************************************/
		if (firstRecord)
			startTime = [[items objectAtIndex:timeIdx] longLongValue];
		
		int itemIdx		= 0;
		for (Variable *v in _vars)
			{
			NSString *val = [items objectAtIndex:itemIdx];
			
			if ([v format] == TIME)
				{
				long long now	= [val longLongValue];
				currentTime = now - startTime;
				}
			else if ([v record])
				{
				uint64_t newVal = (uint64_t)-1;
				
				if ([v format] == HEX)
					{
					NSScanner* scanner = [NSScanner scannerWithString:val];
					[scanner scanHexLongLong:&newVal];
					}
				else
					newVal = [val longLongValue];
				
				if (newVal != [v value])
					{
					[v setValue:newVal];
					[v setIsDirty:true];
					changes = true;
					}
				if (firstRecord)
					[v setIsDirty:true];
				}
				
			itemIdx ++;
			}

		/********************************************************************\
		|* Output any new state
		\********************************************************************/
		if (changes)
			{
			fprintf(_ofp, "#%lld\n", currentTime);
			
			for (Variable *v in _vars)
				{
				if ([v isDirty])
					{
					fprintf(_ofp, "%s\n", [[v vcdFormat] UTF8String]);
					[v setIsDirty:false];
					}
				}
			}
		
		firstRecord = false;
		}
	return true;
	}
@end
