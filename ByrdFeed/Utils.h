//
//  Utils.h
//  Findr
//
//  Created by Eddie Freeman on 6/17/14.
//  Copyright (c) 2014 NinjaSudo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (void)loadImageUrl:(NSURL *)url inImageView:(UIImageView *)imageView withAnimation:(BOOL)enableAnimation;

+ (void)loadImageUrl:(NSURL *)url inImageView:(UIImageView *)imageView withAnimation:(BOOL)enableAnimation
             success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
             failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

@end
