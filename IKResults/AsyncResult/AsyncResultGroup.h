//
//  AsyncResultGroup.h
//  IKResults
//
//  Created by Ian Keen on 30/06/2015.
//  Copyright (c) 2015 IanKeen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncResult.h"

typedef void(^asyncResultGroupFinally)(NSArray *results);

@interface AsyncResultGroup : NSObject
/**
 *  Represents a group of future `Results`
 *
 *  @param asyncResults an `NSArray` of `AsyncResult`s
 *
 *  @return new AsyncResultGroup
 */
+(instancetype)with:(NSArray *)asyncResults;

/**
 *  A block that is called for each successful `AsyncResult` with the underlying value
 *  iff the Result was successful
 */
@property (nonatomic, strong, readonly) AsyncResultGroup * (^success)(resultSuccess success);

/**
 *  A block that is called for each unsuccessful `AsyncResult` with the underlying NSError
 *  iff the Result was unsuccessful
 */
@property (nonatomic, strong, readonly) AsyncResultGroup * (^failure)(resultFailure failure);

/**
 *  A block that is called upon fulfillment of all `AsyncResult`s in this group
 *  the value is an NSArray of `Result`s which can be either successes or failures
 */
@property (nonatomic, strong, readonly) AsyncResultGroup * (^finally)(asyncResultGroupFinally finally);
@end
