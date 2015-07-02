//
//  AsyncResultGroupSpec.m
//  IKResults
//
//  Created by Ian Keen on 2/07/2015.
//  Copyright 2015 IanKeen. All rights reserved.
//

#import "Specta.h"
#import <Expecta/Expecta.h>
#import "AsyncResultGroup.h"

//resolve keyword clash
#undef failure
#define _failure(...) EXP_failure((__VA_ARGS__))

static AsyncResult * asyncTask(NSInteger delay, BOOL succeed) {
    AsyncResult *result = [AsyncResult asyncResult];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Result *r = (succeed ? [Result success:@YES] : [Result failure:[NSError errorWithDomain:@"err" code:0 userInfo:nil]]);
        [result fulfill:r];
    });
    return result;
}
static AsyncResult * syncTask(BOOL succeed) {
    Result *result = (succeed ? [Result success:@YES] : [Result failure:[NSError errorWithDomain:@"err" code:0 userInfo:nil]]);
    return [AsyncResult asyncResult:result];
}


SpecBegin(AsyncResultGroup)

describe(@"AsyncResultGroup", ^{
    it(@"should handle sync tasks", ^{
        __block NSInteger successCount = 0;
        __block NSInteger failCount = 0;
        __block NSArray *resultArray = nil;
        
        AsyncResultGroup *group = [AsyncResultGroup with:@[syncTask(YES), syncTask(NO)]];
        group.success(^(id value) {
            successCount++;
        }).failure(^(NSError *error) {
            failCount++;
        }).finally(^(NSArray *results) {
            resultArray = results;
        });
        
        expect(successCount).will.equal(1);
        expect(failCount).will.equal(1);
        
        Result *result1 = resultArray.firstObject;
        Result *result2 = resultArray.lastObject;
        expect(result1.isSuccess).will.equal(YES);
        expect(result2.isFailure).will.equal(YES);
    });
    
    it(@"should handle async tasks", ^{
        __block NSInteger successCount = 0;
        __block NSInteger failCount = 0;
        __block NSArray *resultArray = nil;
        
        AsyncResultGroup *group = [AsyncResultGroup with:@[asyncTask(2, YES), asyncTask(1, NO)]];
        group.success(^(id value) {
            successCount++;
        }).failure(^(NSError *error) {
            failCount++;
        }).finally(^(NSArray *results) {
            resultArray = results;
        });
        
        expect(successCount).after(2.0).will.equal(1);
        expect(failCount).after(2.0).will.equal(1);
        
        Result *result1 = resultArray.firstObject;
        Result *result2 = resultArray.lastObject;
        expect(result1.isSuccess).after(2.0).will.equal(YES);
        expect(result2.isFailure).after(2.0).will.equal(YES);
    });
    
    it(@"should handle mixed tasks", ^{
        __block NSInteger successCount = 0;
        __block NSInteger failCount = 0;
        __block NSArray *resultArray = nil;
        
        AsyncResultGroup *group = [AsyncResultGroup with:@[asyncTask(2, YES), syncTask(NO)]];
        group.success(^(id value) {
            successCount++;
        }).failure(^(NSError *error) {
            failCount++;
        }).finally(^(NSArray *results) {
            resultArray = results;
        });
        
        expect(successCount).after(2.0).will.equal(1);
        expect(failCount).after(2.0).will.equal(1);
        
        Result *result1 = resultArray.firstObject;
        Result *result2 = resultArray.lastObject;
        expect(result1.isSuccess).after(2.0).will.equal(YES);
        expect(result2.isFailure).after(2.0).will.equal(YES);
    });
});

SpecEnd
