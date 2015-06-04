#import "Specta.h"
#import <Expecta/Expecta.h>
#import "AsyncResult.h"

//resolve keyword clash
#undef failure
#define _failure(...) EXP_failure((__VA_ARGS__))

AsyncResult * delayedResult(NSTimeInterval duration, BOOL success) {
    AsyncResult *result = [AsyncResult new];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (success) {
            [result fulfill:[Result success:@YES]];
        } else {
            [result fulfill:[Result failure:[NSError errorWithDomain:@"Title" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Desc"}]]];
        }
    });
    return result;
}
AsyncResult * invalidDelayedResult(NSTimeInterval duration, BOOL success) {
    AsyncResult *result = [AsyncResult new];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (success) {
            [result fulfill:[Result success:nil]];
        } else {
            [result fulfill:[Result failure:nil]];
        }
    });
    return result;
}

SpecBegin(AsyncResult)

describe(@"AsyncResult", ^{
    
    context(@"Created with initial values", ^{
        it(@"should execute success when initialied with a successful Result", ^{
            __block BOOL outcome = NO;
            
            Result *result = [Result success:@YES];
            AsyncResult *async = [AsyncResult asyncResult:result];
            async.success(^(id value) {
                outcome = YES;
            }).failure(^(NSError *error) {
                
            });
            
            expect(outcome).will.equal(YES);
        });
        it(@"should execute failure when initialied with unsuccessful Result", ^{
            __block BOOL outcome = NO;
            
            Result *result = [Result failure:[NSError errorWithDomain:@"Title" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Desc"}]];
            AsyncResult *async = [AsyncResult asyncResult:result];
            async.success(^(id value) {
                
            }).failure(^(NSError *error) {
                outcome = YES;
            });
            
            expect(outcome).will.equal(YES);
        });
        
        it(@"should execute failure when initialied with successful Result with no value", ^{
            __block BOOL outcome = NO;
            
            Result *result = [Result success:nil];
            AsyncResult *async = [AsyncResult asyncResult:result];
            async.success(^(id value) {
                
            }).failure(^(NSError *error) {
                outcome = YES;
            });
            
            expect(outcome).will.equal(YES);
        });
        it(@"should execute failure when initialied with unsuccessful Result with no value", ^{
            __block BOOL outcome = NO;
            
            Result *result = [Result failure:nil];
            AsyncResult *async = [AsyncResult asyncResult:result];
            async.success(^(id value) {
                
            }).failure(^(NSError *error) {
                outcome = YES;
            });
            
            expect(outcome).will.equal(YES);
        });
        
        it(@"should compose successfully when all Results are successful", ^{
            __block BOOL outcome = NO;
            
            Result *result = [Result success:@"test"];
            AsyncResult *async = [AsyncResult asyncResult:result];
            async.map(^(NSString *value) {
                return [value uppercaseString];
            }).map(^(NSString *value) {
                return [value stringByAppendingString:@"_"];
            }).success(^(NSString *value) {
                outcome = ([value isEqualToString:@"TEST_"]);
            }).failure(^(NSError *error) {
                
            });
            
            expect(outcome).will.equal(YES);
        });
        it(@"should fail early when a composed element fails", ^{
            __block BOOL outcome = NO;
            
            Result *result = [Result failure:[NSError errorWithDomain:@"Title" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Desc"}]];
            AsyncResult *async = [AsyncResult asyncResult:result];
            async.map(^(NSString *value) {
                _failure(@"");
                return [value uppercaseString];
            }).map(^(NSString *value) {
                _failure(@"");
                return [value stringByAppendingString:@"_"];
            }).success(^(NSString *value) {
                _failure(@"");
            }).failure(^(NSError *error) {
                outcome = YES;
            });
            
            expect(outcome).will.equal(YES);
        });
    });

    context(@"Created without initial values", ^{
        it(@"should execute success when fulfilled with a successful Result", ^{
            __block BOOL outcome = NO;
            
            delayedResult(0.5, YES).success(^(id value) {
                outcome = YES;
            }).failure(^(NSError *error) {
                
            });
            
            expect(outcome).will.equal(YES);
        });
        it(@"should execute failure when fulfilled with an unsuccessful Result", ^{
            __block BOOL outcome = NO;
            
            delayedResult(0.5, NO).success(^(id value) {
                
            }).failure(^(NSError *error) {
                outcome = YES;
            });
            
            expect(outcome).will.equal(YES);
        });
        
        it(@"should execute failure when fulfilled with successful Result with no value", ^{
            __block BOOL outcome = NO;
            
            invalidDelayedResult(0.5, YES).success(^(id value) {
                
            }).failure(^(NSError *error) {
                outcome = YES;
            });
            
            expect(outcome).will.equal(YES);
        });
        it(@"should execute failure when fulfilled with unsuccessful Result with no value", ^{
            __block BOOL outcome = NO;
            
            invalidDelayedResult(0.5, NO).success(^(id value) {
                
            }).failure(^(NSError *error) {
                outcome = YES;
            });
            
            expect(outcome).will.equal(YES);
        });
        
        it(@"should compose successfully when all Results are successful", ^{
            __block BOOL outcome = NO;
            
            delayedResult(0.5, YES)
            .flatMapAsync(^(NSNumber *result) { return delayedResult(0.5, [result boolValue]); })
            .flatMapAsync(^(NSNumber *result) { return delayedResult(0.5, [result boolValue]); })
            .success(^(NSNumber *value) {
                outcome = [value boolValue];
            }).failure(^(NSError *error) {
                
            });
            
            expect(outcome).after(2.0).will.equal(YES);
        });
        it(@"should fail early when a composed element fails", ^{
            __block BOOL outcome = NO;
            
            delayedResult(0.5, YES)
            .flatMapAsync(^(id result) { return delayedResult(0.5, NO); })
            .flatMapAsync(^(id result) { _failure(@""); return delayedResult(0.5, YES); })
            .success(^(id value) {
                
            }).failure(^(NSError *error) {
                outcome = YES;
            });
            
            expect(outcome).after(2.0).will.equal(YES);
        });
    });
    
});

SpecEnd
