#import <Foundation/Foundation.h>

@class Result;

extern NSError * error(NSString *title, NSString *desc);

@interface ResultFunctions : NSObject
-(Result *)stringResult:(NSString *)string;
-(Result *)stringToUppercase:(NSString *)string;
-(Result *)stringWithTestSuffix:(NSString *)string;
-(Result *)stringWithTestPrefix:(NSString *)string;

-(Result *)stringWithFailure:(NSString *)result;
@end
