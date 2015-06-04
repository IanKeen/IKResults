# IKResults

Super simple fail-fast or railway oriented programming (why should swift have all the shiny things? ;)).

IKResults provides two very simple classes for helping to deal with the synchronous and asynchronous flow of your code. They not only improve the readability but the ease with which you can reason about otherwise complex code paths.

## Result
Result represents the success or failure of a synchronous operation.

### Creating a Result
Creating a function that returns a Result couldn't be easier.
```objectivec
-(Result *)somethingThatCouldFail {
	if (failed) {
    	NSError *error = ...;
    	return [Result failure:error];
        
	} else {
    	id successfulVaue = ...;
        return [Result success:successfulValue];
	}
}
```
Great.. so how is that helpful? Well the power of this is when you `compose` these methods together in a chain.

### Composing methods with Result
For example if you are performing an operation that has multiple steps that could potentially fail, normally you might write:
```objectivec
-(void)sometingThatHasMultipleSteps {
	if ([self step1]) {
    	if ([self step2]) {
        	if ([self step3]) { 
            	//do something once all steps succeed!
            }
        }
    }
}
-(BOOL)step1 { ... }
-(BOOL)step2 { ... }
-(BOOL)step3 { ... }
```
This is pretty common place in most code bases but writing this way kind of sucks.. for starters we have no idea which step failed or why

So how can we make this nicer?.. We could use a pointer to an NSError I hear you say? sure!, lets try..
```objectivec
-(void)sometingThatHasMultipleSteps:(NSError **)error {
	if ([self step1:error]) {
    	if ([self step2:error]) {
        	if ([self step3:error]) { 
            	//do something once all steps succeed!
            }
        }
    }
}
-(BOOL)step1:(NSError **)error { ... }
-(BOOL)step2:(NSError **)error { ... }
-(BOOL)step3:(NSError **)error { ... }
```
Awesome, now we know which step failed and why!.. but what if we needed something other than a BOOL from one step to parse to the next? we need to compose the methods together.., we could make another change..
```objectivec
-(void)sometingThatHasMultipleSteps:(NSError **)error {
	NSString *step1String = [self step1:error];
    if (!error) {
    	NSString *step2String = [self step2:step1String error:error];
        if (!error) {
    		NSString *step3String = [self step3:step2String error:error];
            if (!error) {
            	//do something with step3String once all steps succeed!
            }
	    }
    }
}
-(NSString *)step1:(NSError **)error { ... }
-(NSString *)step2:(NSString *)input error:(NSError **)error { ... }
-(NSString *)step3:(NSString *)input error:(NSError **)error { ... }
```
Sweet, now we know which step failed and why, and the functions are composed together.. but we still have that right lean and its not any easier to read..

Using `Result` as a return type you can write the following code:
```objectivec
-(void)sometingThatHasMultipleSteps {
	Result *result = [self step1]
    .flatMapTo(self, @selector(step2:))
    .flatMapTo(self, @selector(step3:))
    .success(^(id finalValue) {
    	//do something with finalValue
    })
    .failure(^(NSError *error) {
    	//handle any errors from any steps
    });
}
-(Result *)step1 { ... }
-(Result *)step2:(NSString *)input { ... }
-(Result *)step3:(NSString *)input { ... }
```
Using `Result` we can simply compose some methods together.. if any steps fail the rest of the chain is skipped and failure() is called with the appropriate error, otherwise success() will be called with the final value

You may have noticed that we are not directly parsing the value forward.. in fact we can't see any variables at all!. Coding in this style allows us to forget about it completely!.. the `flatMap` methods will take care of it all for you.

Using this style we don't need to worry about providing an initial NSError pointer or performing any error checking at all! *and* we have removed the right lean

All we are left with is a clear list of steps and the code that should execute depending on the outcome.

Ok thats great.. but what if my steps are asynchronous!, I'm glad you asked..

## AsyncResult
AsyncResult represents the *future* success or failure of an asynchronous operation. It is essentially a very *basic* Promise implementation using `Result` to provide the same control flow benefits

### Creating an AsyncResult
Creating a function that returns an AsyncResult is just as simple as `Result`.
```objectivec
-(AsyncResult *)somethingThatCouldFailInTheFuture {
	AsyncResult *futureResult = [AsyncResult asyncResult];
    
    dispatch_async(queue, ^{
    	
    	/* perform some asynchronous task.. */
        
        if (failed) {
    		NSError *error = ...;
    		[futureResult fulfill:[Result failure:error]];
        
		} else {
    		id successfulVaue = ...;
        	[futureResult fulfill:[Result success:successfulValue]];
		}
    });
    
    return futureResult;
}
```
Simple right? The point to take away here is that `futureResult` is returned immediately even though the asynchronous operation is still running. Once it finishes it fulfills `futureResult` with a `Result` object that represents wether it succeeded or not.

Once an `AsyncResult` is fulfilled any methods you have chained off it will execute just like `Result`.
```objectivec
-(void)doSomethingInTheFuture {
	[self somethingThatCouldFailInTheFuture]
    .success(^(id finalValue) {
    	//do something with finalValue
    })
    .failure(^(NSError *error) {
    	//handle error
    })
    .finally(^{
    	//code is always executed regardless of success/failure
    });
}

-(AsyncResult *)somethingThatCouldFailInTheFuture { ... }
```
`AsyncResult` provides an additional `finally()` block.

### Composing asynchronous methods with AsyncResult
Sound good? Ok, so what about when you have one asynchronous method that depends on the successful execution of another asynchronous method? I'm sure you have all seen code like this..
```objectivec
-(void)doAsyncTasks {
	[self asyncTask1:^(id successfulValue1) {
    	[self asyncTask2:successfulValue1 success:^(id successfulValue2) {
        	//yay! do something with successfulValue2
            
        } failure:^(NSError *error) {
        	//handle error..
        }];
    } failure:^(NSError *error) {
    	//handle error..
    }];
}

-(void)asyncTask1:(void (^)(id successfulValue))success failure:(void (^)(NSError *error))failure { ... }
-(void)asyncTask2With:(id)input success:(void (^)(id successfulValue))success failure:(void (^)(NSError *error))failure { ... }
```
Yep it works.. but we have right lean multiple points of failure that need handling, sure we could simplify this..
```objectivec
-(void)doAsyncTasks {
	void (^errorHandler)(NSError *) = ^(NSError *error) {
    	//handle error..
    };

	[self asyncTask1:^(id successfulValue1) {
    	[self asyncTask2:successfulValue1 success:^(id successfulValue2) {
        	//yay! do something with successfulValue2
            
        } failure:errorHandler];
    } failure:errorHandler];
}
```
Much nicer! We still have some right lean.. BUT we have DRYed up the code.. however we have now increased the cognitive complexity. The code is now harder to reason about because the error handling happens.. first? Wouldn't it be nicer if the code read in order?

Using `AsyncResult` as the return type for your methods you can write the following code:
```objectivec
-(void)doAsyncTasks {
	[self asyncTask1]
    .flatMapAsyncSelector(self, @selector(asyncTask2:))
    .success(^(id finalValue) {
    	//do something with finalValue
    })
    .failure(^(NSError *error) {
    	//handle any errors from any steps
    });
}
-(AsyncResult *)asyncTask1 { ... }
-(AsyncResult *)asyncTask2:(id)input { ... }
```
So how did the parameters get parsed on?!?.. don't worry.. the `flatMap` methods take care or forwarding the successful result of one operation to the next!

Much like `Result` this code reads easily and in the order it executes with all the same benefits.


### More on chaining
There are some other little tricks you can achieve with `AsyncResult` such as transforming (or mapping) successful values before sending them on to `success()` or other asynchronous methods. If we expand on the previous example
```objectivec
-(void)doAsyncTasks {
	[self asyncTask1]
    .flatMapAsyncSelector(self, @selector(asyncTask2:))
    .map(^NSNumber *value) {
    	/* for some reason we need to change the number 
        we got from asyncTask2: into a NSString for asyncTask3:
        (don't ask me why :P .. just roll with it)
        */
        return [NSString stringWithFormat:@"%@", value];
    })
    .flatMapAsyncSelector(self, @selector(asyncTask3:))
    .success(^(id finalValue) {
    	//do something with finalValue
    })
    .failure(^(NSError *error) {
    	//handle any errors from any steps
    });
}
-(AsyncResult *)asyncTask1 { ... }
-(AsyncResult *)asyncTask2:(NSNumber *)input { ... }
-(AsyncResult *)asyncTask3:(NSString *)input { ... }
```
Here we can see we have easily added a third asynchronous operation *and* we have transformed the value inbetween `asyncTask2:` and `asyncTask3:` with ease!

# Installation
Install via cocoapods by adding the following to your Podfile
```
pod "IKResults", "~>1.0"
```
or manually by adding Result.(h|m) and AsyncResult.(h|m) to your project

# The rest..
Pull Requests are welcome!

If you use this in a project I would love to hear about it!.. even if this simply helps you gets a better understanding of the benefits of coding in this way!

If you want a more full featured Promise implementation check out the amazing [PromiseKit](http://promisekit.org/). They also have fantastic documentation!

### Contact
I'm usually hanging out on [iOS Developers](http://ios-developers.io/). You should check them out!
