//
//  AsyncResult
//
//  Created by Ian Keen on 2/06/2015.
//  Copyright (c) 2015 IanKeen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Result.h"

#define IKASYNCRESULT

@class AsyncResult;
typedef AsyncResult * (^flatMapAsyncResultFunction)(id value);

/**
 *  A promise-like object that represents the success or failure of an asynchronous operation sometime in the future
 *  It can be used to compose asynchronous functions and blocks whose output is of type AsyncResult
 *  to provide a 'fail-fast' or 'railroad' style design
 */
@interface AsyncResult : NSObject
/**
 *  Creates a new instance that represents a not-yet-complete asynchronous operation
 *
 *  @return Unfulfilled AsyncResult
 */
+(instancetype)asyncResult;

/**
 *  Creates a new instance that represents the Result of an already completed asynchronous operation
 *
 *  @param result The Result instance representing the value
 *
 *  @return Fulfilled AsyncResult
 */
+(instancetype)asyncResult:(Result *)result;

/**
 *  Fulfills the Result of a completed asynchronous operation
 *
 *  @param result Result instance representing the success or failure of the operation
 */
-(void)fulfill:(Result *)result;

/**
 *  A block that is called upon fulfillment with the underlying successful value
 *  iff the Result was successful
 *
 *  This should only be used *once* per chain
 */
@property (nonatomic, strong, readonly) AsyncResult * (^success)(resultSuccess success);

/**
 *  A block that is called upon fulfillment with the underlying NSError
 *  iff the Result was unsuccessful
 *
 *  This should only be used *once* per chain
 */
@property (nonatomic, strong, readonly) AsyncResult * (^failure)(resultFailure failure);

/**
 *  A block that is called upon fulfillment after either success or failure
 *
 *  This should only be used *once* per chain
 */
@property (nonatomic, strong, readonly) AsyncResult * (^finally)(dispatch_block_t finally);


/**
 *  A block that is called upon fulfillment with the underlying successful value
 *  iff the Result was successful. It can be used to transform the successful value into something else
 *
 *  This can be called multiple times in a chain
 */
@property (nonatomic, strong, readonly) AsyncResult * (^map)(mapResultFunction function);

/**
 *  A selector that is called upon fulfillment with the underlying successful value
 *  iff the Result was successful. It can be used to transform the successful value into something else
 *
 *  This can be called multiple times in a chain
 */
@property (nonatomic, strong, readonly) AsyncResult * (^mapTo)(id object, SEL selector);

/**
 *  A block that is called upon fulfillment with the underlying successful value
 *  iff the Result was successful. It can be used to transform the successful value into 
 *  another Result instance that can be either a success or failure
 *
 *  This can be called multiple times in a chain
 */
@property (nonatomic, strong, readonly) AsyncResult * (^flatMap)(flatMapResultFunction function);

/**
 *  A selector that is called upon fulfillment with the underlying successful value
 *  iff the Result was successful. It can be used to transform the successful value into
 *  another Result instance that can be either a success or failure
 *
 *  This can be called multiple times in a chain
 */
@property (nonatomic, strong, readonly) AsyncResult * (^flatMapTo)(id object, SEL selector);

/**
 *  A block that is called upon fulfillment with the underlying successful value
 *  iff the Result was successful. It can be used to parse the successful value into
 *  another asynchronous operation that also returns an AsyncResult
 *
 *  This can be called multiple times in a chain
 */
@property (nonatomic, strong, readonly) AsyncResult * (^flatMapAsync)(flatMapAsyncResultFunction function);

/**
 *  A selector that is called upon fulfillment with the underlying successful value
 *  iff the Result was successful. It can be used to parse the successful value into
 *  another asynchronous operation that also returns an AsyncResult
 *
 *  This can be called multiple times in a chain
 */
@property (nonatomic, strong, readonly) AsyncResult * (^flatMapAsyncTo)(id object, SEL selector);
@end
