//
//  AsyncResult
//
//  Created by Ian Keen on 2/06/2015.
//  Copyright (c) 2015 IanKeen. All rights reserved.
//

#import "AsyncResult.h"

typedef void(^asyncResultFulfilled)(Result *result);

@interface AsyncResult ()
@property (nonatomic, strong) Result *result;

@property (nonatomic, strong) asyncResultFulfilled thenBlock;
@property (nonatomic, strong, readonly) AsyncResult * (^then)(asyncResultFulfilled);
@end

@interface Result ()
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSError *error;
@end

#define PERFORM_SELECTOR_WITHOUT_WARNINGS(code) _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") code; _Pragma("clang diagnostic pop")

@implementation AsyncResult
-(instancetype)initWithResult:(Result *)result {
    self = [super init];
    if (self) {
        self.result = result;
    }
    return self;
}

+(instancetype)asyncResult {
    return [self asyncResult:nil];
}
+(instancetype)asyncResult:(Result *)result {
    return [[self alloc] initWithResult:result];
}

-(void)fulfill:(Result *)result {
    self.result = result;
    self.then(self.thenBlock);
}

-(AsyncResult *(^)(asyncResultFulfilled))then {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResult *(asyncResultFulfilled function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.result == nil) {
            //no result yet..
            strongSelf.thenBlock = function;
            
        } else if (function != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                function(strongSelf.result);
            });
        }
        
        return strongSelf;
    };
}
-(AsyncResult *(^)(resultSuccess))success {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResult *(resultSuccess function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AsyncResult *new = [AsyncResult asyncResult];
        strongSelf.then(^(Result *result) {
            if (result.isSuccess) {
                function(result.value);
            }
            [new fulfill:result];
        });
        return new;
    };
}
-(AsyncResult *(^)(resultFailure))failure {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResult *(resultFailure function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AsyncResult *new = [AsyncResult asyncResult];
        strongSelf.then(^(Result *result) {
            if (result.isFailure) {
                function(result.error);
            }
            [new fulfill:result];
        });
        return new;
    };
}
-(AsyncResult *(^)(dispatch_block_t))finally {
    __weak typeof(self) weakSelf = self;
    return ^(dispatch_block_t function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AsyncResult *new = [AsyncResult asyncResult];
        strongSelf.then(^(Result *result) {
            function();
            [new fulfill:result];
        });
        return new;
    };
}

-(AsyncResult *(^)(mapResultFunction))map {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResult *(mapResultFunction function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AsyncResult *new = [AsyncResult asyncResult];
        strongSelf.then(^(Result *result) {
            if (result.isSuccess) {
                [new fulfill:result.map(function)];
            } else {
                [new fulfill:result];
            }
        });
        return new;
    };
}
-(AsyncResult *(^)(id, SEL))mapTo {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResult *(id object, SEL selector) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AsyncResult *new = [AsyncResult asyncResult];
        strongSelf.then(^(Result *result) {
            if (result.isSuccess) {
                if ([object respondsToSelector:selector]) {
                    PERFORM_SELECTOR_WITHOUT_WARNINGS(id functionResult = [object performSelector:selector withObject:result.value])
                    [new fulfill:functionResult];
                    
                } else {
                    NSError *error = [NSError errorWithDomain:NSStringFromSelector(_cmd) code:0 userInfo:@{NSLocalizedDescriptionKey: @"Object does not respond to provided selector"}];
                    [new fulfill:[Result failure:error]];
                }
            } else {
                [new fulfill:result];
            }
        });
        return new;
    };
}

-(AsyncResult *(^)(flatMapResultFunction))flatMap {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResult *(flatMapResultFunction function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AsyncResult *new = [AsyncResult asyncResult];
        strongSelf.then(^(Result *result) {
            if (result.isSuccess) {
                [new fulfill:result.flatMap(function)];
            } else {
                [new fulfill:result];
            }
        });
        return new;
    };
}
-(AsyncResult *(^)(id, SEL))flatMapTo {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResult *(id object, SEL selector) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AsyncResult *new = [AsyncResult asyncResult];
        strongSelf.then(^(Result *result) {
            if (result.isSuccess) {
                if ([object respondsToSelector:selector]) {
                    PERFORM_SELECTOR_WITHOUT_WARNINGS(id functionResult = [object performSelector:selector withObject:result.value])
                    if ([functionResult isKindOfClass:[Result class]]) {
                        [new fulfill:functionResult];
                        
                    } else {
                        NSError *error = [NSError errorWithDomain:NSStringFromSelector(_cmd) code:0 userInfo:@{NSLocalizedDescriptionKey: @"Return value is not of type 'Result'"}];
                        [new fulfill:[Result failure:error]];
                    }
                } else {
                    NSError *error = [NSError errorWithDomain:NSStringFromSelector(_cmd) code:0 userInfo:@{NSLocalizedDescriptionKey: @"Object does not respond to provided selector"}];
                    [new fulfill:[Result failure:error]];
                }
            } else {
                [new fulfill:result];
            }
        });
        return new;
    };
}

-(AsyncResult *(^)(flatMapAsyncResultFunction))flatMapAsync {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResult *(flatMapAsyncResultFunction function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AsyncResult *new = [AsyncResult asyncResult];
        strongSelf.then(^(Result *result) {
            if (result.isSuccess) {
                function(result.value).then(^(Result *innerResult) {
                    [new fulfill:innerResult];
                });
            } else {
                [new fulfill:result];
            }
        });
        return new;
    };
}
-(AsyncResult *(^)(id, SEL))flatMapAsyncTo {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResult *(id object, SEL selector) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AsyncResult *new = [AsyncResult asyncResult];
        strongSelf.then(^(Result *result) {
            if (result.isSuccess) {
                if ([object respondsToSelector:selector]) {
                    PERFORM_SELECTOR_WITHOUT_WARNINGS(AsyncResult *functionResult = [object performSelector:selector withObject:result.value])
                    if ([functionResult isKindOfClass:[AsyncResult class]]) {
                        functionResult.then(^(Result *innerResult) {
                            [new fulfill:innerResult];
                        });
                        
                    } else {
                        NSError *error = [NSError errorWithDomain:NSStringFromSelector(_cmd) code:0 userInfo:@{NSLocalizedDescriptionKey: @"Return value is not of type 'AsyncResult'"}];
                        [new fulfill:[Result failure:error]];
                    }
                } else {
                    NSError *error = [NSError errorWithDomain:NSStringFromSelector(_cmd) code:0 userInfo:@{NSLocalizedDescriptionKey: @"Object does not respond to provided selector"}];
                    [new fulfill:[Result failure:error]];
                }
                
            } else {
                [new fulfill:result];
            }
        });
        return new;
    };
}
@end