//
//  MainViewController.m
//  ByrdFeed
//
//  Created by Eddie Freeman on 6/26/14.
//  Copyright (c) 2014 NinjaSudo Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MainViewController.h"
#import "TimelineTableViewController.h"
#import "MenuPanelViewController.h"
#import "Constants.h"
#import "TwitterClient.h"

#define CORNER_RADIUS 4
#define CENTER_TAG 1
#define MENU_PANEL_TAG 2

#define SLIDE_TIMING .25
#define PANEL_WIDTH 60

@interface MainViewController () <TimelineTableViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) TimelineTableViewController *timelineViewController;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) MenuPanelViewController *menuPanelViewController;

@property (nonatomic, assign) BOOL showingLeftPanel;
@property (nonatomic, assign) BOOL showingRightPanel;

@property (nonatomic, assign) BOOL showPanel;
@property (nonatomic, assign) CGPoint preVelocity;

@property (nonatomic, strong) UITapGestureRecognizer *tapCloseGesture;

@end

@implementation MainViewController

#pragma mark -
#pragma mark View Did Load/Unload

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  /* check if we have a current user, if not login */
  
  if (![[TwitterClient sharedInstance] isLoggedIn]){
    [[TwitterClient sharedInstance] login];
  }
  else {
    [self setupView];
  }
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

#pragma mark -
#pragma mark View Will/Did Appear

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

#pragma mark -
#pragma mark View Will/Did Disappear

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Setup View

- (void)setupView
{
  NSLog(@"Show Timeline");
  // Setup timeline view
  self.timelineViewController = [[TimelineTableViewController alloc] initWithNibName:nil bundle:nil];
  self.timelineViewController.view.tag = CENTER_TAG;
  self.timelineViewController.delegate = self;
  
  self.navigationController = [[UINavigationController alloc] initWithRootViewController:_timelineViewController];
  self.navigationController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
  
  /* add the tweet colors to things */
  UIColor * lightBlueColor = [UIColor colorWithRed:90/255.0f green:192/255.0f blue:251/255.0f alpha:1.0f];
  [self.navigationController.navigationBar setBarTintColor:lightBlueColor];
  [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
  [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
  [self.navigationController.navigationBar setTranslucent:YES];
  
  [self.view addSubview:_navigationController.view];
  [self addChildViewController:_navigationController];
  
  [_navigationController didMoveToParentViewController:self];
  
  [self setupGestures];
}

- (void)showCenterViewWithShadow:(BOOL)value withOffset:(double)offset
{
  if (value)
  {
    [_navigationController.view.layer setCornerRadius:CORNER_RADIUS];
    [_navigationController.view.layer setShadowColor:[UIColor blackColor].CGColor];
    [_navigationController.view.layer setShadowOpacity:0.8];
    [_navigationController.view.layer setShadowOffset:CGSizeMake(offset, offset)];
    
  }
  else
  {
    [_navigationController.view.layer setCornerRadius:0.0f];
    [_navigationController.view.layer setShadowOffset:CGSizeMake(offset, offset)];
  }
}

- (void)resetMainView
{
  // remove left and right views, and reset variables, if needed
  if (_menuPanelViewController != nil)
  {
    [self.menuPanelViewController.view removeFromSuperview];
    self.menuPanelViewController = nil;
    
#warning Check if on left or right
    self.showingLeftPanel = NO;
    self.showingRightPanel = NO;
  }
  
  [_navigationController.view removeGestureRecognizer:self.tapCloseGesture];
  
  // remove view shadows
  [self showCenterViewWithShadow:NO withOffset:0];
}

- (UIView *)getLeftView
{
  // init view if it doesn't already exist
  if (_menuPanelViewController == nil)
  {
    // this is where you define the view for the left panel
#warning Set Left View
    self.menuPanelViewController = [[MenuPanelViewController alloc] initWithNibName:@"LeftMenuPanelViewController" bundle:nil];
    self.menuPanelViewController.view.tag = MENU_PANEL_TAG;
    self.menuPanelViewController.delegate = _timelineViewController;
    
    [self.view addSubview:self.menuPanelViewController.view];
    
    [self addChildViewController:_menuPanelViewController];
    [_menuPanelViewController didMoveToParentViewController:self];
    
    _menuPanelViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
  }
  
  self.showingLeftPanel = YES;
  
  // set up view shadows
  [self showCenterViewWithShadow:YES withOffset:-2];
  
  UIView *view = self.menuPanelViewController.view;
  return view;
}

- (UIView *)getRightView
{
  // init view if it doesn't already exist
  if (_menuPanelViewController == nil)
  {
    // this is where you define the view for the right panel
    self.menuPanelViewController = [[MenuPanelViewController alloc] initWithNibName:@"RightMenuPanelViewController" bundle:nil];
    self.menuPanelViewController.view.tag = MENU_PANEL_TAG;
    self.menuPanelViewController.delegate = _timelineViewController;
    
    [self.view addSubview:self.menuPanelViewController.view];
    
    [self addChildViewController:self.menuPanelViewController];
    [_menuPanelViewController didMoveToParentViewController:self];
    
    _menuPanelViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
  }
  
  self.showingRightPanel = YES;
  
  // set up view shadows
  [self showCenterViewWithShadow:YES withOffset:2];
  
  UIView *view = self.menuPanelViewController.view;
  return view;
}

#pragma mark -
#pragma mark Swipe Gesture Setup/Actions

#pragma mark - setup

- (void)setupGestures
{
  UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movePanel:)];
  [panRecognizer setMinimumNumberOfTouches:1];
  [panRecognizer setMaximumNumberOfTouches:1];
  [panRecognizer setDelegate:self];
  
  [_navigationController.view addGestureRecognizer:panRecognizer];
  
  self.tapCloseGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetPanel:)];
  [self.tapCloseGesture setNumberOfTapsRequired:1];
  [self.tapCloseGesture setDelegate:self];
}

- (void)resetPanel:(id)sender {
  if([(UITapGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
    [self movePanelToOriginalPosition];
  }
}

- (void)movePanel:(id)sender
{
  [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
  
  CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];
  CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];
  
  if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
    UIView *childView = nil;
    
    if(velocity.x > 0) {
      if (!_showingRightPanel) {
        childView = [self getLeftView];
      }
    }
    else {
      if (!_showingLeftPanel) {
        childView = [self getRightView];
      }
    }
    // Make sure the view you're working with is front and center.
    [self.view sendSubviewToBack:childView];
    [[sender view] bringSubviewToFront:[(UIPanGestureRecognizer*)sender view]];
  }
  
  if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
    if(velocity.x > 0) {
//      NSLog(@"gesture went right");
    }
    else {
//      NSLog(@"gesture went left");
    }
    
    if (!_showPanel) {
      [self movePanelToOriginalPosition];
    }
    else {
      if (_showingLeftPanel) {
        [self movePanelRight];
      }
      else if (_showingRightPanel) {
        [self movePanelLeft];
      }
      [_navigationController.view addGestureRecognizer:self.tapCloseGesture];
    }
  }
  
  if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateChanged) {
    if(velocity.x > 0) {
//      NSLog(@"gesture went right");
    }
    else {
//      NSLog(@"gesture went left");
    }
    
    // Are you more than halfway? If so, show the panel when done dragging by setting this value to YES (1).
    _showPanel = abs([sender view].center.x - _navigationController.view.frame.size.width/2) > _navigationController.view.frame.size.width/2;
    
    // Allow dragging only in x-coordinates by only updating the x-coordinate with translation position.
    [sender view].center = CGPointMake([sender view].center.x + translatedPoint.x, [sender view].center.y);
    [(UIPanGestureRecognizer*)sender setTranslation:CGPointMake(0,0) inView:self.view];
    
    // If you needed to check for a change in direction, you could use this code to do so.
    if(velocity.x*_preVelocity.x + velocity.y*_preVelocity.y > 0) {
//      NSLog(@"same direction");
    }
    else {
//      NSLog(@"opposite direction");
    }
    
    _preVelocity = velocity;
  }
}

#pragma mark -
#pragma mark Delegate Actions

- (void)movePanelLeft // to show right panel
{
  UIView *childView = [self getRightView];
  [self.view sendSubviewToBack:childView];
  
  [UIView animateWithDuration:SLIDE_TIMING delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     _navigationController.view.frame = CGRectMake(-self.view.frame.size.width + PANEL_WIDTH, 0, self.view.frame.size.width, self.view.frame.size.height);
                   }
                   completion:^(BOOL finished) {
                     if (finished) {
#warning identify right
                     }
                   }];
}

- (void)movePanelRight // to show left panel
{
  UIView *childView = [self getLeftView];
  [self.view sendSubviewToBack:childView];
  
  [UIView animateWithDuration:SLIDE_TIMING delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     _navigationController.view.frame = CGRectMake(self.view.frame.size.width - PANEL_WIDTH, 0, self.view.frame.size.width, self.view.frame.size.height);
                   }
                   completion:^(BOOL finished) {
                     if (finished) {
#warning identify left
                     }
                   }];
}

- (void)movePanelToOriginalPosition
{
  [UIView animateWithDuration:SLIDE_TIMING delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     _navigationController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                   }
                   completion:^(BOOL finished) {
                     if (finished) {
                       [self resetMainView];
                     }
                   }];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupView) name:UserLoggedInNotification object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end