//
//  Result
//
//  Created by Ian Keen on 2/06/2015.
//  Copyright (c) 2015 IanKeen. All rights reserved.
//

#import "Result.h"

@interface Result ()
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSError *error;
@end

#define PERFORM_SELECTOR_WITHOUT_WARNINGS(code) _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") code; _Pragma("clang diagnostic pop")

void runOnMainQueueWithoutDeadlocking(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

mapResultFunction mapSelector(id target, SEL selector) {
    mapResultFunction function = ^Result *(id value) {
        if ([target respondsToSelector:selector]) {
            PERFORM_SELECTOR_WITHOUT_WARNINGS(id functionResult = [target performSelector:selector withObject:value])
            return [Result success:functionResult];
        } else {
            NSError *error = [NSError errorWithDomain:@(__func__) code:0 userInfo:@{NSLocalizedDescriptionKey: @"Object does not respond to provided selector"}];
            return [Result failure:error];
        }
    };
    return function;
}
flatMapResultFunction flatMapSelector(id target, SEL selector) {
    flatMapResultFunction function = ^Result *(id value) {
        if ([target respondsToSelector:selector]) {
            PERFORM_SELECTOR_WITHOUT_WARNINGS(id functionResult = [target performSelector:selector withObject:value])
            if ([functionResult isKindOfClass:[Result class]]) {
                return (Result *)functionResult;
                
            } else {
                NSError *error = [NSError errorWithDomain:@(__func__) code:0 userInfo:@{NSLocalizedDescriptionKey: @"Return value is not of type 'Result'"}];
                return [Result failure:error];
            }
        } else {
            NSError *error = [NSError errorWithDomain:@(__func__) code:0 userInfo:@{NSLocalizedDescriptionKey: @"Object does not respond to provided selector"}];
            return [Result failure:error];
        }
    };
    return function;
}

@implementation Result
-(instancetype)init {
    @throw [NSException exceptionWithName:@"Result" reason:@"Please use the +success or +failure class constructors" userInfo:nil];
}
-(instancetype)initWithSuccess:(id)value failure:(NSError *)error {
    self = [super init];
    if (self) {
        if (value == nil && error == nil) {
            self.error = [NSError errorWithDomain:NSStringFromSelector(_cmd) code:0 userInfo:@{NSLocalizedDescriptionKey: @"Invalid data provided to constructor, success value or failure must be provided"}];
        } else {
            self.value = value;
            self.error = error;
        }
    }
    return self;
}

+(instancetype)success:(id)value {
    Result *instance = [[Result alloc] initWithSuccess:value failure:nil];
    return instance;
}
+(instancetype)failure:(NSError *)error {
    Result *instance = [[Result alloc] initWithSuccess:nil failure:error];
    return instance;
}

-(BOOL)isSuccess { return self.value != nil; }
-(BOOL)isFailure { return self.error != nil; }

-(Result * (^)(mapResultFunction))map {
    __weak typeof(self) weakSelf = self;
    return ^Result *(mapResultFunction function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.isFailure) { return [Result failure:strongSelf.error]; }
        return [Result success:function(strongSelf.value)];
    };
}
-(Result *(^)(id, SEL))mapTo {
    return ^Result *(id object, SEL selector) {
        return self.map(mapSelector(object, selector));
    };
}
-(Result * (^)(flatMapResultFunction))flatMap {
    __weak typeof(self) weakSelf = self;
    return ^Result *(mapResultFunction function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.isFailure) { return [Result failure:strongSelf.error]; }
        return function(strongSelf.value);
    };
}
-(Result *(^)(id, SEL))flatMapTo {
    return ^Result *(id object, SEL selector) {
        return self.flatMap(flatMapSelector(object, selector));
    };
}

-(Result * (^)(resultSuccess))success {
    __weak typeof(self) weakSelf = self;
    return ^Result *(resultSuccess function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.isSuccess) {
            runOnMainQueueWithoutDeadlocking(^{
                function(strongSelf.value);
            });
        }
        
        return strongSelf;
    };
}
-(Result * (^)(resultFailure))failure {
    __weak typeof(self) weakSelf = self;
    return ^Result *(resultFailure function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.isFailure) {
            runOnMainQueueWithoutDeadlocking(^{
                function(strongSelf.error);
            });
        }
        
        return strongSelf;
    };
}

-(BOOL)isEqual:(Result *)object {
    if (self.isSuccess && object.isSuccess) {
        return ([self.value isEqual:object.value]);
    } else if (self.isFailure && object.isFailure) {
        return ([self.error isEqual:object.error]);
    }
    return NO;
}
@end
