//
//  AFHTTPSessionManager+RACSupport.m
//
//  Created by dairugang on 2016/12/23.
//  Copyright (c) 2015 makeiteasy. All rights reserved.
//

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)

#import "AFHTTPSessionManager+RACSupport.h"

NSString *const RACAFNResponseObjectErrorKey = @"responseObject";

@implementation AFHTTPSessionManager (RACSupport)

- (RACSignal *)rac_GET:(NSString *)path parameters:(id)parameters {
	return [[self rac_requestPath:path parameters:parameters method:@"GET"]
			setNameWithFormat:@"%@ -rac_GET: %@, parameters: %@", self.class, path, parameters];
}

- (RACSignal *)rac_HEAD:(NSString *)path parameters:(id)parameters {
	return [[self rac_requestPath:path parameters:parameters method:@"HEAD"]
			setNameWithFormat:@"%@ -rac_HEAD: %@, parameters: %@", self.class, path, parameters];
}

- (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters {
	return [[self rac_requestPath:path parameters:parameters method:@"POST"]
			setNameWithFormat:@"%@ -rac_POST: %@, parameters: %@", self.class, path, parameters];
}

- (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:nil];
		
		NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
			if (error) {
				NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
        			if (responseObject) {
					userInfo[RACAFNResponseObjectErrorKey] = responseObject;
          			}
        			NSError *errorWithRes = [NSError errorWithDomain:error.domain code:error.code userInfo:[userInfo copy]];
				[subscriber sendError:errorWithRes];
			} else {
				[subscriber sendNext:RACTuplePack(responseObject, response)];
				[subscriber sendCompleted];
			}
		}];
		[task resume];
		
		return [RACDisposable disposableWithBlock:^{
			[task cancel];
		}];
	}] setNameWithFormat:@"%@ -rac_POST: %@, parameters: %@, constructingBodyWithBlock:", self.class, path, parameters];
;
}

- (RACSignal *)rac_PUT:(NSString *)path parameters:(id)parameters {
	return [[self rac_requestPath:path parameters:parameters method:@"PUT"]
			setNameWithFormat:@"%@ -rac_PUT: %@, parameters: %@", self.class, path, parameters];
}

- (RACSignal *)rac_PATCH:(NSString *)path parameters:(id)parameters {
	return [[self rac_requestPath:path parameters:parameters method:@"PATCH"]
			setNameWithFormat:@"%@ -rac_PATCH: %@, parameters: %@", self.class, path, parameters];
}

- (RACSignal *)rac_DELETE:(NSString *)path parameters:(id)parameters {
	return [[self rac_requestPath:path parameters:parameters method:@"DELETE"]
			setNameWithFormat:@"%@ -rac_DELETE: %@, parameters: %@", self.class, path, parameters];
}

- (RACSignal *)rac_requestPath:(NSString *)path parameters:(id)parameters method:(NSString *)method {
	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		NSURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
		
		NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
			NSLog(@"%@", [self debugNetworkResponseDescription:task responseObject:responseObject error:error]);
			if (error) {
				NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
				if (responseObject) {
					userInfo[RACAFNResponseObjectErrorKey] = responseObject;
				}
				NSError *errorWithRes = [NSError errorWithDomain:error.domain code:error.code userInfo:[userInfo copy]];
				[subscriber sendError:errorWithRes];
			} else {
				[subscriber sendNext:RACTuplePack(responseObject, response)];
				[subscriber sendCompleted];
			}
		}];
		[task resume];
		NSLog(@"%@", [self debugNetworkRequestDescription:task.currentRequest]);
		
		return [RACDisposable disposableWithBlock:^{
			[task cancel];
		}];
	}];
}

#pragma mark - debug
- (NSString *)curlCommandLineString:(NSURLRequest *)request
{
    __block NSMutableString *displayString = [NSMutableString stringWithFormat:@"curl -X %@", request.HTTPMethod];
    
    [displayString appendFormat:@" \'%@\'",  request.URL.absoluteString];
    
    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop) {
        [displayString appendFormat:@" -H \'%@: %@\'", key, val];
    }];
    
    if ([request.HTTPMethod isEqualToString:@"POST"] ||
        [request.HTTPMethod isEqualToString:@"PUT"] ||
        [request.HTTPMethod isEqualToString:@"PATCH"]) {
        
        [displayString appendFormat:@" -d \'%@\'",
         [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]];
    }
    
    return displayString;
}

- (NSString *)debugNetworkRequestDescription:(NSURLRequest *)request
{
    NSMutableString *displayString = [NSMutableString stringWithFormat:@"\n-------- 时间： %@\n请求报文：\n-------\n%@",
                                      [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]],
                                      [self curlCommandLineString:request]];
    
    return displayString;
}

- (NSString *)debugNetworkResponseDescription:(NSURLSessionDataTask * _Nonnull)task
                               responseObject:(id)responseObject
                                        error:(NSError *)error
{
    NSMutableString *displayString = [NSMutableString stringWithFormat:@"\n-------- 时间： %@\n返回报文：(url:%@)\n",
                                      [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]],
                                      task.currentRequest.URL.absoluteString];
    
    if (responseObject) {
        [displayString appendFormat:@"--------\n%@\n", responseObject];
    }
    
    if (error) {
        [displayString appendFormat:@"--------\nerror: %@\n", error];
    }
    
    return displayString;
}

@end

#endif
