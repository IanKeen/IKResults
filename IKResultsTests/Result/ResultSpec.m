#import "Specta.h"
#import "Result.h"
#import "ResultFunctions.h"
#import <Expecta/Expecta.h>

//resolve keyword clash
#undef failure
#define _failure(...) EXP_failure((__VA_ARGS__))

SpecBegin(Result)

describe(@"Result", ^{
    it(@"should succeed when initialied with success and a value", ^{
        Result *result = [Result success:@YES];
        expect(result.isSuccess).to.beTruthy();
    });
    it(@"should fail when initialied with success and no value", ^{
        [Result success:nil].success(^(id value) {
            _failure(@"");
        }).failure(^(NSError *err) {
            expect(err).notTo.beNil();
        });
    });
    
    it(@"should succeed when initialied with failure and a NSError", ^{
        Result *result = [Result failure:[NSError errorWithDomain:@"Title" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Desc"}]];
        expect(result.isFailure).to.beTruthy();
    });
    it(@"should fail when initialied with failure and no value", ^{
        [Result failure:nil].success(^(id value) {
            _failure(@"");
        }).failure(^(NSError *err) {
            expect(err).notTo.beNil();
        });
    });
    
    it(@"should fire the success block when created with success", ^{
        [Result success:@YES].success(^(NSNumber *value) {
            expect(value).to.equal(@YES);
        }).failure(^(NSError *error) {
            _failure(@"Fail.");
        });
    });
    it(@"should fire the failure block when created with failure", ^{
        NSError *e = [NSError errorWithDomain:@"Title" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Desc"}];
        [Result failure:e].success(^(NSNumber *value) {
            _failure(@"");
        }).failure(^(NSError *err) {
            expect(err).to.beIdenticalTo(e);
        });
    });
    
    it(@"should map a successful result to a new value", ^{
        [Result success:@"value"].map(^(NSString *value) {
            return [value uppercaseString];
        }).success(^(NSString *value) {
            expect(value).to.equal(@"VALUE");
        }).failure(^(NSError *e) {
            _failure(@"");
        });
    });
    
    it(@"should map a successful Result to a new successful Result", ^{
        ResultFunctions *functions = [ResultFunctions new];
        
        [Result success:@"value"].flatMap(^(NSString *value) {
            return [functions stringResult:[value uppercaseString]];
        }).success(^(NSString *value) {
            expect(value).to.equal(@"VALUE");
        }).failure(^(NSError *e) {
            _failure(@"");
        });
    });
    
    
    it(@"should compose multiple Result functions together to produce a success value", ^{
        ResultFunctions *functions = [ResultFunctions new];
        
        [Result success:@"value"]
        .flatMapTo(functions, @selector(stringToUppercase:))
        .flatMapTo(functions, @selector(stringWithTestSuffix:))
        .flatMapTo(functions, @selector(stringWithTestPrefix:))
        .success(^(NSString *value) {
            expect(value).to.equal(@"prefix_VALUE_test");
        }).failure(^(NSError *e) {
            _failure(@"");
        });
    });
    
    it(@"should return failure if any of the links in the chain fail", ^{
        ResultFunctions *functions = [ResultFunctions new];
        
        [Result success:@"value"]
        .flatMapTo(functions, @selector(stringToUppercase:))
        .flatMapTo(functions, @selector(stringWithFailure:))
        .flatMapTo(functions, @selector(stringWithTestPrefix:))
        .success(^(NSString *value) {
            _failure(@"should have failed");
        }).failure(^(NSError *e) {
            expect(e).toNot.beNil();
        });

    });
});

SpecEnd
