//
//  AsyncResultGroup.m
//  IKResults
//
//  Created by Ian Keen on 30/06/2015.
//  Copyright (c) 2015 IanKeen. All rights reserved.
//

#import "AsyncResultGroup.h"

@interface AsyncResultGroup ()
@property (nonatomic, strong) AsyncResult *internalAsyncResult;
@property (nonatomic, strong) NSArray *asyncResults;
@property (nonatomic, strong) NSMutableArray *asyncResultResults;

@property (nonatomic, copy) resultSuccess successBlock;
@property (nonatomic, copy) resultFailure failureBlock;
@property (nonatomic, copy) asyncResultGroupFinally finallyBlock;
@end

@interface AsyncResult (Private)
@property (nonatomic, strong) Result *result;
@end

@interface Result (Private)
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSError *error;
@end

@implementation AsyncResultGroup
#pragma mark - Lifecycle
+(instancetype)with:(NSArray *)asyncResults {
    return [[self alloc] initWith:asyncResults];
}
-(instancetype)initWith:(NSArray *)asyncResults {
    if (!(self = [super init])) { return nil; }
    NSMutableArray *placeholder = [NSMutableArray array];
    for (NSInteger index = 0; index < asyncResults.count; index++) {
        [placeholder addObject:[NSNull null]];
    }
    self.asyncResultResults = placeholder;
    self.asyncResults = [NSArray arrayWithArray:asyncResults];
    self.internalAsyncResult = [self synchronisedAsyncResults];
    return self;
}

#pragma mark - Public
-(AsyncResultGroup *(^)(resultSuccess))success {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResultGroup *(resultSuccess function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.internalAsyncResult.result != nil) {
            [strongSelf publishSuccess:function];
        } else {
            strongSelf.successBlock = function;
        }
         
        return strongSelf;
    };
}
-(AsyncResultGroup *(^)(resultFailure))failure {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResultGroup *(resultFailure function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.internalAsyncResult.result != nil) {
            [strongSelf publishFailure:function];
        } else {
            strongSelf.failureBlock = function;
        }
         
        return strongSelf;
    };
}
-(AsyncResultGroup *(^)(asyncResultGroupFinally))finally {
    __weak typeof(self) weakSelf = self;
    return ^AsyncResultGroup *(asyncResultGroupFinally function) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.internalAsyncResult.result != nil) {
            [strongSelf publishFinally:function];
        } else {
            strongSelf.finallyBlock = function;
        }
        
        return strongSelf;
    };
}

#pragma mark - Private
-(AsyncResult *)synchronisedAsyncResults {
    __block NSInteger completeCount = 0;
    
    AsyncResult *result = [AsyncResult asyncResult];
    
    [self.asyncResults enumerateObjectsUsingBlock:^(AsyncResult *obj, NSUInteger idx, BOOL *stop) {
        obj.success(^(id value) {
            self.asyncResultResults[idx] = [Result success:value];
            
        }).failure(^(NSError *error) {
            self.asyncResultResults[idx] = [Result failure:error];
            
        }).finally(^{
            completeCount++;
            if (completeCount >= self.asyncResults.count) {
                [result fulfill:[Result success:@YES]];
            }
        });
    }];
    
    return result.finally(^{
        [self publishToBlocks];
    });
}

-(void)publishToBlocks {
    [self publishSuccess:self.successBlock];
    [self publishFailure:self.failureBlock];
    [self publishFinally:self.finallyBlock];
}
-(void)publishFinally:(asyncResultGroupFinally)block {
    if (block == nil) { return; }
    block([self.asyncResultResults copy]);
}
-(void)publishSuccess:(resultSuccess)block {
    if (block == nil) { return; }
    
    [self.asyncResultResults enumerateObjectsUsingBlock:^(Result *obj, NSUInteger idx, BOOL *stop) {
        if (obj.isSuccess) {
            block(obj.value);
        }
    }];
}
-(void)publishFailure:(resultFailure)block {
    if (block == nil) { return; }
    
    [self.asyncResultResults enumerateObjectsUsingBlock:^(Result *obj, NSUInteger idx, BOOL *stop) {
        if (obj.isFailure) {
            block(obj.error);
        }
    }];
}
@end
