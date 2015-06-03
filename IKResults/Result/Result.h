//
//  Result
//
//  Created by Ian Keen on 2/06/2015.
//  Copyright (c) 2015 IanKeen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IKRESULT

@class Result;

typedef id (^mapResultFunction)(id value);
typedef Result * (^flatMapResultFunction)(id value);

typedef void(^resultSuccess)(id value);
typedef void(^resultFailure)(NSError *error);

/**
 *  A simple structure that represents a success or failure of an operation
 *  It can be used to compose functions and blocks whose output is of type Result
 *  to provide a 'fail-fast' or 'railroad' style design
 */
@interface Result : NSObject
/**
 *  Create a sucessful Result
 *
 *  @param value Actual value of the successful operation (must not be nil)
 *
 *  @return Successful Result
 */
+(instancetype)success:(id)value;

/**
 *  Create an unsuccessful Result
 *
 *  @param error NSError that describes the reason an operation failed (must not be nil)
 *
 *  @return Unsuccessful Result
 */
+(instancetype)failure:(NSError *)error;

/**
 *  @return YES if the receiver represents success
 */
-(BOOL)isSuccess;

/**
 *  @return YES if the receiver represents failure
 */
-(BOOL)isFailure;

/**
 *  A block that is called with the underlying successful value iff this Result was successful
 */
@property (nonatomic, strong, readonly) Result * (^success)(resultSuccess success);

/**
 *  A block that is called with the underlying NSError iff this Result was unsuccessful
 */
@property (nonatomic, strong, readonly) Result * (^failure)(resultFailure failure);

/**
 *  A block that is called with the successful value iff this Result was successful
 *  A new successful Result is created with the output of the block
 */
@property (nonatomic, strong, readonly) Result * (^map)(mapResultFunction function);

/**
 *  A selector that is called with the successful value iff this Result was successful
 *  A new successful Result is created with the output of the selector
 */
@property (nonatomic, strong, readonly) Result * (^mapTo)(id object, SEL selector);

/**
 *  A block that is called with the successful value iff this Result was successful
 *  A new Result instance should be returned that can be either a success or failure
 */
@property (nonatomic, strong, readonly) Result * (^flatMap)(flatMapResultFunction function);

/**
 *  A selector that is called with the successful value iff this Result was successful
 *  A new Result instance should be returned that can be either a success or failure
 */
@property (nonatomic, strong, readonly) Result * (^flatMapTo)(id object, SEL selector);
@end
