//
//  IKResultsCommon.h
//  IKResults
//
//  Created by Ian Keen on 1/07/2015.
//  Copyright (c) 2015 IanKeen. All rights reserved.
//

#define PERFORM_SELECTOR_WITHOUT_WARNINGS(code) _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") code; _Pragma("clang diagnostic pop")

static void runOnMainQueueSafely(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}