//
//  UserBoxView.h
//  ByrdFeed
//
//  Created by Eddie Freeman on 7/1/14.
//  Copyright (c) 2014 NinjaSudo Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@class UserBoxView;

@protocol UserBoxViewDelegate <NSObject>

@required
- (void)onTapProfileImage:(User *)user;

@end

@interface UserBoxView : UIView

@property (strong, nonatomic) User *user;
@property (weak, nonatomic) id<UserBoxViewDelegate>delegate;

@end
