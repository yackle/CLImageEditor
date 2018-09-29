//
//  _CLImageEditorViewController.m
//
//  Created by sho yakushiji on 2013/11/05.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "_CLImageEditorViewController.h"

#import "CLImageToolBase.h"


#pragma mark- _CLImageEditorViewController

static const CGFloat kNavBarHeight = 44.0f;
static const CGFloat kMenuBarHeight = 80.0f;

@interface _CLImageEditorViewController()
<CLImageToolProtocol, UINavigationBarDelegate>
@property (nonatomic, strong) CLImageToolBase *currentTool;
@property (nonatomic, strong, readwrite) CLImageToolInfo *toolInfo;
@property (nonatomic, strong) UIImageView *targetImageView;
@end


@implementation _CLImageEditorViewController
{
    UIImage *_originalImage;
    UIView *_bgView;
}
@synthesize toolInfo = _toolInfo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.toolInfo = [CLImageToolInfo toolInfoForToolClass:[self class]];
    }
    return self;
}

- (id)init
{
    self = [self initWithNibName:nil bundle:nil];
    if (self){
        
    }
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    return [self initWithImage:image delegate:nil];
}

- (id)initWithImage:(UIImage*)image delegate:(id<CLImageEditorDelegate>)delegate
{
    self = [self init];
    if (self){
        _originalImage = [image deepCopy];
        self.delegate = delegate;
    }
    return self;
}

- (id)initWithDelegate:(id<CLImageEditorDelegate>)delegate
{
    self = [self init];
    if (self){
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [_navigationBar removeFromSuperview];
}

#pragma mark- Custom initialization

- (UIBarButtonItem*)createDoneButton
{
    UIBarButtonItem *rightBarButtonItem = nil;
    NSString *doneBtnTitle = [CLImageEditorTheme localizedString:@"CLImageEditor_DoneBtnTitle" withDefault:nil];
    
    if(![doneBtnTitle isEqualToString:@"CLImageEditor_DoneBtnTitle"]){
        rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:doneBtnTitle style:UIBarButtonItemStyleDone target:self action:@selector(pushedFinishBtn:)];
    }
    else{
        rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pushedFinishBtn:)];
    }
    return rightBarButtonItem;
}

- (void)initNavigationBar
{
    self.navigationItem.rightBarButtonItem = [self createDoneButton];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    if(_navigationBar==nil){
        UINavigationItem *navigationItem  = [[UINavigationItem alloc] init];
        navigationItem.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(pushedCloseBtn:)];
        navigationItem.rightBarButtonItem = [self createDoneButton];
        
        CGFloat dy = MIN([UIApplication sharedApplication].statusBarFrame.size.height, [UIApplication sharedApplication].statusBarFrame.size.width);
        
        UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, dy, self.view.width, kNavBarHeight)];
        [navigationBar pushNavigationItem:navigationItem animated:NO];
        navigationBar.delegate = self;
        
        if(self.navigationController){
            [self.navigationController.view addSubview:navigationBar];
            [_CLImageEditorViewController setConstraintsLeading:@0 trailing:@0 top:nil bottom:nil height:@(kNavBarHeight) width:nil parent:self.navigationController.view child:navigationBar peer:nil];
        }
        else{
            [self.view addSubview:navigationBar];
            if (@available(iOS 11.0, *)) {
                [_CLImageEditorViewController setConstraintsLeading:@0 trailing:@0 top:nil bottom:nil height:@(kNavBarHeight) width:nil parent:self.view child:navigationBar peer:nil];
                [_CLImageEditorViewController setConstraintsLeading:nil trailing:nil top:@0 bottom:nil height:nil width:nil parent:self.view child:navigationBar peer:self.view.safeAreaLayoutGuide];
            } else {
                [_CLImageEditorViewController setConstraintsLeading:@0 trailing:@0 top:@(dy) bottom:nil height:@(kNavBarHeight) width:nil parent:self.view child:navigationBar peer:nil];
            }
        }
        _navigationBar = navigationBar;
    }
    
    if(self.navigationController!=nil){
        _navigationBar.frame  = self.navigationController.navigationBar.frame;
        _navigationBar.hidden = YES;
        [_navigationBar popNavigationItemAnimated:NO];
    }
    else{
        _navigationBar.topItem.title = self.title;
    }
    
    if([UIDevice iosVersion] < 7){
        _navigationBar.barStyle = UIBarStyleBlackTranslucent;
    }
}

- (void)initMenuScrollView
{
    if(self.menuView==nil){
        UIScrollView *menuScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, kMenuBarHeight)];
        
        // Adjust for iPhone X
        if (@available(iOS 11.0, *)) {
            UIEdgeInsets theInsets = [UIApplication sharedApplication].keyWindow.rootViewController.view.safeAreaInsets;
            menuScroll.height += theInsets.bottom;
        }
        
        menuScroll.top = self.view.height - menuScroll.height;
        menuScroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        menuScroll.showsHorizontalScrollIndicator = NO;
        menuScroll.showsVerticalScrollIndicator = NO;
        
        [self.view addSubview:menuScroll];
        self.menuView = menuScroll;
        [_CLImageEditorViewController setConstraintsLeading:@0 trailing:@0 top:nil bottom:@0 height:@(menuScroll.height) width:nil parent:self.view child:menuScroll peer:nil];
    }
    self.menuView.backgroundColor = [CLImageEditorTheme toolbarColor];
}

- (void)initImageScrollView
{
    if(_scrollView==nil){
        UIScrollView *imageScroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        imageScroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageScroll.showsHorizontalScrollIndicator = NO;
        imageScroll.showsVerticalScrollIndicator = NO;
        imageScroll.delegate = self;
        imageScroll.clipsToBounds = NO;
        
        CGFloat y = 0;
        if(self.navigationController){
            if(self.navigationController.navigationBar.translucent){
                y = self.navigationController.navigationBar.bottom;
            }
            y = ([UIDevice iosVersion] < 7) ? y-[UIApplication sharedApplication].statusBarFrame.size.height : y;
        }
        else{
            y = _navigationBar.bottom;
        }
        
        imageScroll.top = y;
        imageScroll.height = self.view.height - imageScroll.top - _menuView.height;
        
        [self.view insertSubview:imageScroll atIndex:0];
        _scrollView = imageScroll;
        
        if (@available(iOS 11.0, *)) {
            [_CLImageEditorViewController setConstraintsLeading:@0 trailing:@0 top:nil bottom:@(-_menuView.height) height:nil width:nil parent:self.view child:imageScroll peer:nil];
            [_CLImageEditorViewController setConstraintsLeading:nil trailing:nil top:@(y) bottom:nil height:nil width:nil parent:self.view child:imageScroll peer:self.view.safeAreaLayoutGuide];
        }
        else{
            [_CLImageEditorViewController setConstraintsLeading:@0 trailing:@0 top:@(y) bottom:@(-_menuView.height) height:nil width:nil parent:self.view child:imageScroll peer:nil];
        }
        
    }
}

+(NSArray <NSLayoutConstraint *>*)setConstraintsLeading:(NSNumber *)leading
                                               trailing:(NSNumber *)trailing
                                                    top:(NSNumber *)top
                                                 bottom:(NSNumber *)bottom
                                                 height:(NSNumber *)height
                                                  width:(NSNumber *)width
                                                 parent:(UIView *)parent
                                                  child:(UIView *)child
                                                   peer:(nullable id)peer
{
    NSMutableArray <NSLayoutConstraint *>*constraints = [NSMutableArray new];
    //Trailing
    if (trailing) {
        NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint
                                                  constraintWithItem:child
                                                  attribute:NSLayoutAttributeTrailing
                                                  relatedBy:NSLayoutRelationEqual
                                                  toItem:(peer ?: parent)
                                                  attribute:NSLayoutAttributeTrailing
                                                  multiplier:1.0f
                                                  constant:trailing.floatValue];
        [parent addConstraint:trailingConstraint];
        [constraints addObject:trailingConstraint];
    }
    //Leading
    if (leading) {
        NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint
                                                 constraintWithItem:child
                                                 attribute:NSLayoutAttributeLeading
                                                 relatedBy:NSLayoutRelationEqual
                                                 toItem:(peer ?: parent)
                                                 attribute:NSLayoutAttributeLeading
                                                 multiplier:1.0f
                                                 constant:leading.floatValue];
        [parent addConstraint:leadingConstraint];
        [constraints addObject:leadingConstraint];
    }
    //Bottom
    if (bottom) {
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint
                                                constraintWithItem:child
                                                attribute:NSLayoutAttributeBottom
                                                relatedBy:NSLayoutRelationEqual
                                                toItem:(peer ?: parent)
                                                attribute:NSLayoutAttributeBottom
                                                multiplier:1.0f
                                                constant:bottom.floatValue];
        [parent addConstraint:bottomConstraint];
        [constraints addObject:bottomConstraint];
    }
    //Top
    if (top) {
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint
                                             constraintWithItem:child
                                             attribute:NSLayoutAttributeTop
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:(peer ?: parent)
                                             attribute:NSLayoutAttributeTop
                                             multiplier:1.0f
                                             constant:top.floatValue];
        [parent addConstraint:topConstraint];
        [constraints addObject:topConstraint];
    }
    //Height
    if (height) {
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint
                                                constraintWithItem:child
                                                attribute:NSLayoutAttributeHeight
                                                relatedBy:NSLayoutRelationEqual
                                                toItem:nil
                                                attribute:NSLayoutAttributeNotAnAttribute
                                                multiplier:1.0f
                                                constant:height.floatValue];
        [child addConstraint:heightConstraint];
        [constraints addObject:heightConstraint];
    }
    //Width
    if (width) {
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint
                                               constraintWithItem:child
                                               attribute:NSLayoutAttributeWidth
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:nil
                                               attribute:NSLayoutAttributeNotAnAttribute
                                               multiplier:1.0f
                                               constant:width.floatValue];
        [child addConstraint:widthConstraint];
        [constraints addObject:widthConstraint];
    }
    child.translatesAutoresizingMaskIntoConstraints = NO;
    return constraints;
}

#pragma mark-

- (void)showInViewController:(UIViewController*)controller withImageView:(UIImageView*)imageView;
{
    _originalImage = imageView.image;
    
    self.targetImageView = imageView;
    
    [controller addChildViewController:self];
    [self didMoveToParentViewController:controller];
    
    self.view.frame = controller.view.bounds;
    [controller.view addSubview:self.view];
    [self refreshImageView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.toolInfo.title;
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = self.theme.backgroundColor;
    self.navigationController.view.backgroundColor = self.view.backgroundColor;
    
    if([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    if([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    [self initNavigationBar];
    [self initMenuScrollView];
    [self initImageScrollView];
    
    [self refreshToolSettings];
    
    if(_imageView==nil){
        _imageView = [UIImageView new];
        [_scrollView addSubview:_imageView];
        [self refreshImageView];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(self.targetImageView){
        [self expropriateImageView];
    }
    else{
        [self refreshImageView];
    }
}

#pragma mark- View transition

- (void)copyImageViewInfo:(UIImageView*)fromView toView:(UIImageView*)toView
{
    CGAffineTransform transform = fromView.transform;
    fromView.transform = CGAffineTransformIdentity;
    
    toView.transform = CGAffineTransformIdentity;
    toView.frame = [toView.superview convertRect:fromView.frame fromView:fromView.superview];
    toView.transform = transform;
    toView.image = fromView.image;
    toView.contentMode = fromView.contentMode;
    toView.clipsToBounds = fromView.clipsToBounds;
    
    fromView.transform = transform;
}

- (void)expropriateImageView
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    
    UIImageView *animateView = [UIImageView new];
    [window addSubview:animateView];
    [self copyImageViewInfo:self.targetImageView toView:animateView];
    
    _bgView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:_bgView atIndex:0];
    
    _bgView.backgroundColor = self.view.backgroundColor;
    self.view.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:0];
    
    self.targetImageView.hidden = YES;
    _imageView.hidden = YES;
    _bgView.alpha = 0;
    _navigationBar.transform = CGAffineTransformMakeTranslation(0, -_navigationBar.height);
    _menuView.transform = CGAffineTransformMakeTranslation(0, self.view.height-_menuView.top);
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         animateView.transform = CGAffineTransformIdentity;
                         
                         CGFloat dy = ([UIDevice iosVersion]<7) ? [UIApplication sharedApplication].statusBarFrame.size.height : 0;
                         
                         CGSize size = (self->_imageView.image) ? self->_imageView.image.size : self->_imageView.frame.size;
                         if(size.width>0 && size.height>0){
                             CGFloat ratio = MIN(self->_scrollView.width / size.width, self->_scrollView.height / size.height);
                             CGFloat W = ratio * size.width;
                             CGFloat H = ratio * size.height;
                             animateView.frame = CGRectMake((self->_scrollView.width-W)/2 + self->_scrollView.left, (self->_scrollView.height-H)/2 + self->_scrollView.top + dy, W, H);
                         }
                         
                         self->_bgView.alpha = 1;
                         self->_navigationBar.transform = CGAffineTransformIdentity;
                         self->_menuView.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished) {
                         self.targetImageView.hidden = NO;
                         self->_imageView.hidden = NO;
                         [animateView removeFromSuperview];
                     }
     ];
}

- (void)restoreImageView:(BOOL)canceled
{
    if(!canceled){
        self.targetImageView.image = _imageView.image;
    }
    self.targetImageView.hidden = YES;
    
    id<CLImageEditorTransitionDelegate> delegate = [self transitionDelegate];
    if([delegate respondsToSelector:@selector(imageEditor:willDismissWithImageView:canceled:)]){
        [delegate imageEditor:self willDismissWithImageView:self.targetImageView canceled:canceled];
    }
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    
    UIImageView *animateView = [UIImageView new];
    [window addSubview:animateView];
    [self copyImageViewInfo:_imageView toView:animateView];
    
    _menuView.frame = [window convertRect:_menuView.frame fromView:_menuView.superview];
    _navigationBar.frame = [window convertRect:_navigationBar.frame fromView:_navigationBar.superview];
    
    [window addSubview:_menuView];
    [window addSubview:_navigationBar];
    
    self.view.userInteractionEnabled = NO;
    _menuView.userInteractionEnabled = NO;
    _navigationBar.userInteractionEnabled = NO;
    _imageView.hidden = YES;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         self->_bgView.alpha = 0;
                         self->_menuView.alpha = 0;
                         self->_navigationBar.alpha = 0;
                         
                         self->_menuView.transform = CGAffineTransformMakeTranslation(0, self.view.height-self->_menuView.top);
                         self->_navigationBar.transform = CGAffineTransformMakeTranslation(0, -self->_navigationBar.height);
                         
                         [self copyImageViewInfo:self.targetImageView toView:animateView];
                     }
                     completion:^(BOOL finished) {
                         [animateView removeFromSuperview];
                         [self->_menuView removeFromSuperview];
                         [self->_navigationBar removeFromSuperview];
                         
                         [self willMoveToParentViewController:nil];
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
                         
                         self->_imageView.hidden = NO;
                         self.targetImageView.hidden = NO;
                         
                         if([delegate respondsToSelector:@selector(imageEditor:didDismissWithImageView:canceled:)]){
                             [delegate imageEditor:self didDismissWithImageView:self.targetImageView canceled:canceled];
                         }
                     }
     ];
}

#pragma mark- Properties

- (id<CLImageEditorTransitionDelegate>)transitionDelegate
{
    if([self.delegate conformsToProtocol:@protocol(CLImageEditorTransitionDelegate)]){
        return (id<CLImageEditorTransitionDelegate>)self.delegate;
    }
    return nil;
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    self.toolInfo.title = title;
}

- (UIScrollView*)scrollView
{
    return _scrollView;
}

#pragma mark- ImageTool setting

+ (NSString*)defaultIconImagePath
{
    return nil;
}

+ (CGFloat)defaultDockedNumber
{
    return 0;
}

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLImageEditor_DefaultTitle" withDefault:@"Edit"];
}

+ (BOOL)isAvailable
{
    return YES;
}

+ (NSArray*)subtools
{
    return [CLImageToolInfo toolsWithToolClass:[CLImageToolBase class]];
}

+ (NSDictionary*)optionalInfo
{
    return nil;
}

#pragma mark-

- (void)refreshToolSettings
{
    for(UIView *sub in _menuView.subviews){ [sub removeFromSuperview]; }
    
    CGFloat x = 0;
    CGFloat W = 70;
    CGFloat H = _menuView.height;
    
    int toolCount = 0;
    CGFloat padding = 0;
    for(CLImageToolInfo *info in self.toolInfo.sortedSubtools){
        if(info.available){
            toolCount++;
        }
    }
    
    CGFloat diff = _menuView.frame.size.width - toolCount * W;
    if (0<diff && diff<2*W) {
        padding = diff/(toolCount+1);
    }
    
    for(CLImageToolInfo *info in self.toolInfo.sortedSubtools){
        if(!info.available){
            continue;
        }
        
        CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x+padding, 0, W, H) target:self action:@selector(tappedMenuView:) toolInfo:info];
        [_menuView addSubview:view];
        x += W+padding;
    }
    _menuView.contentSize = CGSizeMake(MAX(x, _menuView.frame.size.width+1), 0);
}

- (void)resetImageViewFrame
{
    CGSize size = (_imageView.image) ? _imageView.image.size : _imageView.frame.size;
    if(size.width>0 && size.height>0){
        CGFloat ratio = MIN(_scrollView.frame.size.width / size.width, _scrollView.frame.size.height / size.height);
        CGFloat W = ratio * size.width * _scrollView.zoomScale;
        CGFloat H = ratio * size.height * _scrollView.zoomScale;
        
        _imageView.frame = CGRectMake(MAX(0, (_scrollView.width-W)/2), MAX(0, (_scrollView.height-H)/2), W, H);
    }
}

- (void)fixZoomScaleWithAnimated:(BOOL)animated
{
    CGFloat minZoomScale = _scrollView.minimumZoomScale;
    _scrollView.maximumZoomScale = 0.95*minZoomScale;
    _scrollView.minimumZoomScale = 0.95*minZoomScale;
    [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:animated];
}

- (void)resetZoomScaleWithAnimated:(BOOL)animated
{
    CGFloat Rw = _scrollView.frame.size.width / _imageView.frame.size.width;
    CGFloat Rh = _scrollView.frame.size.height / _imageView.frame.size.height;
    
    //CGFloat scale = [[UIScreen mainScreen] scale];
    CGFloat scale = 1;
    Rw = MAX(Rw, _imageView.image.size.width / (scale * _scrollView.frame.size.width));
    Rh = MAX(Rh, _imageView.image.size.height / (scale * _scrollView.frame.size.height));
    
    _scrollView.contentSize = _imageView.frame.size;
    _scrollView.minimumZoomScale = 1;
    _scrollView.maximumZoomScale = MAX(MAX(Rw, Rh), 1);
    
    [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:animated];
}

- (void)refreshImageView
{
    _imageView.image = _originalImage;
    
    [self resetImageViewFrame];
    [self resetZoomScaleWithAnimated:NO];
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

- (BOOL)shouldAutorotate
{
    return (_currentTool == nil);
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskAll;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self resetImageViewFrame];
    [self refreshToolSettings];
    [self scrollViewDidZoom:_scrollView];
}

- (BOOL)prefersStatusBarHidden
{
    return [[CLImageEditorTheme theme] statusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [[CLImageEditorTheme theme] statusBarStyle];
}

#pragma mark- Tool actions

- (void)setCurrentTool:(CLImageToolBase *)currentTool
{
    if(currentTool != _currentTool){
        [_currentTool cleanup];
        _currentTool = currentTool;
        [_currentTool setup];
        
        [self swapToolBarWithEditing:(_currentTool!=nil)];
    }
}

#pragma mark- Menu actions

- (void)swapMenuViewWithEditing:(BOOL)editing
{
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         if(editing){
                             self->_menuView.transform = CGAffineTransformMakeTranslation(0, self.view.height-self->_menuView.top);
                         }
                         else{
                             self->_menuView.transform = CGAffineTransformIdentity;
                         }
                     }
     ];
}

- (void)swapNavigationBarWithEditing:(BOOL)editing
{
    if(self.navigationController==nil){
        return;
    }
    
    if(editing){
        _navigationBar.hidden = NO;
        _navigationBar.transform = CGAffineTransformMakeTranslation(0, -_navigationBar.height);
        
        [UIView animateWithDuration:kCLImageToolAnimationDuration
                         animations:^{
                             self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationController.navigationBar.height-20);
                             self->_navigationBar.transform = CGAffineTransformIdentity;
                         }
         ];
    }
    else{
        [UIView animateWithDuration:kCLImageToolAnimationDuration
                         animations:^{
                             self.navigationController.navigationBar.transform = CGAffineTransformIdentity;
                             self->_navigationBar.transform = CGAffineTransformMakeTranslation(0, -self->_navigationBar.height);
                         }
                         completion:^(BOOL finished) {
                             self->_navigationBar.hidden = YES;
                             self->_navigationBar.transform = CGAffineTransformIdentity;
                         }
         ];
    }
}

- (void)swapToolBarWithEditing:(BOOL)editing
{
    [self swapMenuViewWithEditing:editing];
    [self swapNavigationBarWithEditing:editing];
    
    if(self.currentTool){
        UINavigationItem *item  = [[UINavigationItem alloc] initWithTitle:self.currentTool.toolInfo.title];
        item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[CLImageEditorTheme localizedString:@"CLImageEditor_OKBtnTitle" withDefault:@"OK"] style:UIBarButtonItemStyleDone target:self action:@selector(pushedDoneBtn:)];
        item.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithTitle:[CLImageEditorTheme localizedString:@"CLImageEditor_BackBtnTitle" withDefault:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(pushedCancelBtn:)];
        
        [_navigationBar pushNavigationItem:item animated:(self.navigationController==nil)];
    }
    else{
        [_navigationBar popNavigationItemAnimated:(self.navigationController==nil)];
    }
}

- (void)setupToolWithToolInfo:(CLImageToolInfo*)info
{
    if(self.currentTool){ return; }
    
    Class toolClass = NSClassFromString(info.toolName);
    
    if(toolClass){
        id instance = [toolClass alloc];
        if(instance!=nil && [instance isKindOfClass:[CLImageToolBase class]]){
            instance = [instance initWithImageEditor:self withToolInfo:info];
            self.currentTool = instance;
        }
    }
}

- (void)tappedMenuView:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
    
    [self setupToolWithToolInfo:view.toolInfo];
}

- (IBAction)pushedCancelBtn:(id)sender
{
    _imageView.image = _originalImage;
    [self resetImageViewFrame];
    
    self.currentTool = nil;
}

- (IBAction)pushedDoneBtn:(id)sender
{
    self.view.userInteractionEnabled = NO;
    
    [self.currentTool executeWithCompletionBlock:^(UIImage *image, NSError *error, NSDictionary *userInfo) {
        if(error){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else if(image){
            self->_originalImage = image;
            self->_imageView.image = image;
            
            [self resetImageViewFrame];
            self.currentTool = nil;
        }
        self.view.userInteractionEnabled = YES;
    }];
}

- (void)pushedCloseBtn:(id)sender
{
    if(self.targetImageView==nil){
        if([self.delegate respondsToSelector:@selector(imageEditorDidCancel:)]){
            [self.delegate imageEditorDidCancel:self];
        }
        else{
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else{
        _imageView.image = self.targetImageView.image;
        [self restoreImageView:YES];
    }
}

- (void)pushedFinishBtn:(id)sender
{
    if(self.targetImageView==nil){
        if([self.delegate respondsToSelector:@selector(imageEditor:didFinishEditingWithImage:)]){
            [self.delegate imageEditor:self didFinishEditingWithImage:_originalImage];
        }
        else if([self.delegate respondsToSelector:@selector(imageEditor:didFinishEdittingWithImage:)]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [self.delegate imageEditor:self didFinishEdittingWithImage:_originalImage];
#pragma clang diagnostic pop
        }
        else{
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else{
        _imageView.image = _originalImage;
        [self restoreImageView:NO];
    }
}

#pragma mark- ScrollView delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat Ws = _scrollView.frame.size.width - _scrollView.contentInset.left - _scrollView.contentInset.right;
    CGFloat Hs = _scrollView.frame.size.height - _scrollView.contentInset.top - _scrollView.contentInset.bottom;
    CGFloat W = _imageView.frame.size.width;
    CGFloat H = _imageView.frame.size.height;
    
    CGRect rct = _imageView.frame;
    rct.origin.x = MAX((Ws-W)/2, 0);
    rct.origin.y = MAX((Hs-H)/2, 0);
    _imageView.frame = rct;
}

@end
