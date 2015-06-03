#import "ResultFunctions.h"
#import "Result.h"

NSError * error(NSString *title, NSString *desc) {
    return [NSError errorWithDomain:title code:0 userInfo:@{NSLocalizedDescriptionKey: desc}];
}

@implementation ResultFunctions
-(Result *)stringResult:(NSString *)string {
    return [Result success:string];
}
-(Result *)stringToUppercase:(NSString *)string {
    if ([string isKindOfClass:[NSString class]]) {
        return [Result success:[string uppercaseString]];
    }
    return [Result failure:error(@"ResultTests", @"Data was not a string")];
}
-(Result *)stringWithTestSuffix:(NSString *)string {
    if ([string isKindOfClass:[NSString class]]) {
        return [Result success:[string stringByAppendingString:@"_test"]];
    }
    return [Result failure:error(@"ResultTests", @"Data was not a string")];

}
-(Result *)stringWithTestPrefix:(NSString *)string {
    if ([string isKindOfClass:[NSString class]]) {
        return [Result success:[@"prefix_" stringByAppendingString:string]];
    }
    return [Result failure:error(@"ResultTests", @"Data was not a string")];
}

-(Result *)stringWithFailure:(NSString *)result {
    return [Result failure:error(@"Test", @"Forced Failure")];
}
@end
