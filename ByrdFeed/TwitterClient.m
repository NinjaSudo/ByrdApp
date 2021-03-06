//
//  TwitterClient.m
//  ByrdFeed
//
//  Created by Eddie Freeman on 6/22/14.
//  Copyright (c) 2014 NinjaSudo Inc. All rights reserved.
//

#import "TwitterClient.h"
#import "PersistencyManager.h"
#import "NSURL+DictionaryFromQueryString.h"

// OAUTH SETUP
#define TWITTER_BASE_URL @"https://api.twitter.com/"

#define TOKEN_REQUEST_PATH @"oauth/request_token"
#define TOKEN_ACCESS_PATH @"oauth/access_token"
#define APP_SCHEME @"nstwitter"
#define TOKEN_CALLBACK_PATH @"oauth"
#define TOKEN_AUTH_URL @"oauth/authorize?oauth_token=%@"

// Endpoints
#define GET_USER_URL @"1.1/account/verify_credentials.json"
#define GET_TIMELINE_URL @"1.1/statuses/home_timeline.json"
#define POST_STATUS_UPDATE_URL @"1.1/statuses/update.json"
#define POST_STATUS_RETWEET_URL @"1.1/statuses/retweet/%@.json"
#define GET_STATUS_RETWEETS_URL @"1.1/statuses/retweets/%@.json"
#define POST_STATUS_UNTWEET_URL @"1.1/statuses/destroy/%@.json"

#define POST_STATUS_FAVORITE_URL @"1.1/favorites/create.json"
#define POST_STATUS_UNFAVORITE_URL @"1.1/favorites/destroy.json"
#define GET_MENTIONS_URL @"1.1/statuses/mentions_timeline.json"
#define GET_MY_TWEETS_URL @"1.1/statuses/user_timeline.json"

static NSString *TWITTER_CONSUMER_KEY;
static NSString *TWITTER_CONSUMER_SECRET;

@interface TwitterClient()

@property (nonatomic, strong) PersistencyManager *persistencyManager;

@end

@implementation TwitterClient

- (id)init
{
  self = [super init];
  if (self) {
    _persistencyManager = [[PersistencyManager alloc] init];
  }
  return self;
}

+ (TwitterClient*)sharedInstance
{
  static TwitterClient *_sharedInstance = nil;
  static dispatch_once_t oncePredicate;
  
  dispatch_once(&oncePredicate, ^{
    
    /* read in api config from plist */
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"TwitterAPI.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
      plistPath = [[NSBundle mainBundle] pathForResource:@"TwitterAPI" ofType:@"plist"];
    }
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format
                                          errorDescription:&errorDesc];
    if (!temp) {
      NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
    }
    
    TWITTER_CONSUMER_KEY = [temp objectForKey:@"TWITTER_CONSUMER_KEY"];
    TWITTER_CONSUMER_SECRET = [temp objectForKey:@"TWITTER_CONSUMER_SECRET"];
    
//    TWITTER_CONSUMER_KEY = [temp objectForKey:@"TWITTER_CONSUMER_KEY_DEV"];
//    TWITTER_CONSUMER_SECRET = [temp objectForKey:@"TWITTER_CONSUMER_SECRET_DEV"];
    
    /* now create the instance */
    _sharedInstance = [[TwitterClient alloc] initWithBaseURL:[NSURL URLWithString:TWITTER_BASE_URL] consumerKey:TWITTER_CONSUMER_KEY consumerSecret:TWITTER_CONSUMER_SECRET];
  });
  
  return _sharedInstance;
}

#pragma mark - Persistency Manager

- (NSArray*)getTweets
{
  return [_persistencyManager getTweets];
}

- (NSArray*)getUsers
{
  return [_persistencyManager getUsers];
}

#pragma mark - OAuth

- (BOOL)isLoggedIn {
  return [[TwitterClient sharedInstance] getCurrentUser] && [TwitterClient sharedInstance].authorized;
}

- (void)login {
  /* remove any existing auth tokens */
	[self deauthorize];
  
  NSURL *tokenCallbackURL = [NSURL URLWithString:[[APP_SCHEME stringByAppendingString:@"://"] stringByAppendingString:TOKEN_CALLBACK_PATH]];
  
  NSLog(@"Fetching Request Token...");
  [self fetchRequestTokenWithPath:TOKEN_REQUEST_PATH
                              method:@"POST"
                              callbackURL:tokenCallbackURL
                              scope:nil
                              success:^(BDBOAuthToken *requestToken) {
    NSLog(@"Success! Request Token received!");
                                
    NSURL *authURL = [NSURL URLWithString:[NSString stringWithFormat:[TWITTER_BASE_URL stringByAppendingString:TOKEN_AUTH_URL], requestToken.token]];
    [[UIApplication sharedApplication] openURL:authURL];
  } failure:^(NSError *error) {
    NSLog(@"Failure: %@", error);
  }];
}

- (BOOL)processAuthResponseURL:(NSURL *)url onSuccess:(void (^)(void))success{
  if ([url.scheme  isEqual: APP_SCHEME]){
    if ([url.host  isEqual: TOKEN_CALLBACK_PATH]){
      NSDictionary *parameters = [url dictionaryFromQueryString];
      if (parameters[@"oauth_token"] && parameters[@"oauth_verifier"]) {
        [self fetchAccessTokenWithPath:TOKEN_ACCESS_PATH
                                method:@"POST"
                          requestToken:[BDBOAuthToken tokenWithQueryString:url.query]
                               success:^(BDBOAuthToken *accessToken) {
                                 // Save our access token
                                 [self.requestSerializer saveAccessToken:accessToken];
                                 
                                 // Call any subsequent success blocks
                                 success();
                               }
                               failure:^(NSError *error) {
                                 NSLog(@"Error: %@", error);
                               }];
        
      }
      return YES;
    }
  }
  return NO;
}

#pragma mark - REST APIs

- (AFHTTPRequestOperation *)getWithEndpointType:(TwitterClientEndpointType)endpointType parameters:(NSMutableDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {

  NSString *endpointTypeString = [[NSString alloc] init];
  
  switch (endpointType) {
    case TwitterClientEndpointUser: {
      endpointTypeString = GET_USER_URL;
      break;
    }
    case TwitterClientEndpointTimeline: {
      endpointTypeString = GET_TIMELINE_URL;
      
      if(!parameters) {
        parameters = [[NSMutableDictionary alloc] init];
      }
      // Grab default number of tweets for timeline
      [parameters addEntriesFromDictionary:@{@"count" : @(20)}];
      break;
    }
    case TwitterClientEndpointMentions: {
      endpointTypeString = GET_MENTIONS_URL;
      break;
    }
    case TwitterClientEndpointMyTweets: {
      endpointTypeString = GET_MY_TWEETS_URL;
      
      if(!parameters) {
        parameters = [[NSMutableDictionary alloc] init];
        [parameters addEntriesFromDictionary:@{ @"screen_name": [User currentUser].screenName }];
      }
      break;
    }
    default:
      break;
  }
  
  return [self GET:endpointTypeString parameters:parameters success:success failure:failure];
}
- (AFHTTPRequestOperation *)postWithEndpointType:(TwitterClientEndpointType)endpointType parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
  
  NSString *endpointTypeString = [[NSString alloc] init];
  
  switch (endpointType) {
    case TwitterClientEndpointAddTweet: {
      endpointTypeString = POST_STATUS_UPDATE_URL;
      break;
    }
    case TwitterClientEndpointReply: {
      endpointTypeString = POST_STATUS_UPDATE_URL;
      break;
    }
    case TwitterClientEndpointRetweet: {
      NSString *tweetId = parameters[@"id"];
      endpointTypeString = [NSString stringWithFormat:POST_STATUS_RETWEET_URL, tweetId];
      break;
    }
    case TwitterClientEndpointFavorite: {
      endpointTypeString = POST_STATUS_FAVORITE_URL;
      break;
    }
    case TwitterClientEndpointUnfavorite: {
      endpointTypeString = POST_STATUS_UNFAVORITE_URL;
      break;
    }
    case TwitterClientEndpointUnTweet: {
      NSString *tweetId = parameters[@"id"];
      endpointTypeString = [NSString stringWithFormat:POST_STATUS_UNTWEET_URL, tweetId];
      break;
    }
    default:
      break;
  }
  
  return [self POST:endpointTypeString parameters:parameters success:success failure:failure];
}

- (User *)getCurrentUser {
  return [User currentUser];
}

@end
