//
//  Tweet.h
//  ByrdFeed
//
//  Created by Eddie Freeman on 6/22/14.
//  Copyright (c) 2014 NinjaSudo Inc. All rights reserved.
//

#import "Mantle.h"
#import "User.h"

@interface Tweet : MTLModel <MTLJSONSerializing>

@property (strong, nonatomic) NSString *tweetID;
@property (strong, nonatomic) NSString *createdAt;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) NSString *location;
@property (nonatomic, assign) NSInteger followerCount;
@property (nonatomic, assign) NSInteger favoritesCount;
@property (nonatomic, assign) NSInteger retweetCount;
@property (nonatomic, assign) BOOL isRetweeted;
@property (nonatomic, assign) BOOL isFavorited;

+ (NSArray *)tweetsWithArray:(NSArray *)array;
- (Tweet *)initWithDictionary:(NSDictionary *)tweetDictionary;

@end
