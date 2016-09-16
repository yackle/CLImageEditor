//
//  ViewController.m
//  CLImageEditorDemo
//
//  Created by sho yakushiji on 2013/11/14.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "ViewController.h"

#import "CLImageEditor.h"

@interface ViewController ()
<CLImageEditorDelegate, CLImageEditorTransitionDelegate, CLImageEditorThemeDelegate>
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //Set a black theme rather than a white one
	/*
    [[CLImageEditorTheme theme] setBackgroundColor:[UIColor blackColor]];
    [[CLImageEditorTheme theme] setToolbarColor:[[UIColor blackColor] colorWithAlphaComponent:0.8]];
    [[CLImageEditorTheme theme] setToolbarTextColor:[UIColor whiteColor]];
    [[CLImageEditorTheme theme] setToolIconColor:@"white"];
    [[CLImageEditorTheme theme] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    */
    [self refreshImageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)pushedNewBtn
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Photo Library", nil];
    [sheet showInView:self.view.window];
}

- (void)pushedEditBtn
{
    if(_imageView.image){
        CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:_imageView.image delegate:self];
        //CLImageEditor *editor = [[CLImageEditor alloc] initWithDelegate:self];
        
        /*
        NSLog(@"%@", editor.toolInfo);
        NSLog(@"%@", editor.toolInfo.toolTreeDescription);
        
        CLImageToolInfo *tool = [editor.toolInfo subToolInfoWithToolName:@"CLToneCurveTool" recursive:NO];
        tool.available = NO;
        
        tool = [editor.toolInfo subToolInfoWithToolName:@"CLRotateTool" recursive:YES];
        tool.available = NO;
        
        tool = [editor.toolInfo subToolInfoWithToolName:@"CLHueEffect" recursive:YES];
        tool.available = NO;
        */
        
        [self presentViewController:editor animated:YES completion:nil];
        //[editor showInViewController:self withImageView:_imageView];
    }
    else{
        [self pushedNewBtn];
    }
}

- (void)pushedSaveBtn
{
    if(_imageView.image){
        NSArray *excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypeMessage];
        
        UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:@[_imageView.image] applicationActivities:nil];
        
        activityView.excludedActivityTypes = excludedActivityTypes;
        activityView.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            if(completed && [activityType isEqualToString:UIActivityTypeSaveToCameraRoll]){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Saved successfully" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        };
        
        [self presentViewController:activityView animated:YES completion:nil];
    }
    else{
        [self pushedNewBtn];
    }
}

#pragma mark- ImagePicker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:image];
    editor.delegate = self;
    
    [picker pushViewController:editor animated:YES];
}
/*
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if([navigationController isKindOfClass:[UIImagePickerController class]] && [viewController isKindOfClass:[CLImageEditor class]]){
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonDidPush:)];
    }
}

- (void)cancelButtonDidPush:(id)sender
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}
*/
#pragma mark- CLImageEditor delegate

- (void)imageEditor:(CLImageEditor *)editor didFinishEdittingWithImage:(UIImage *)image
{
    _imageView.image = image;
    [self refreshImageView];
    
    [editor dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageEditor:(CLImageEditor *)editor willDismissWithImageView:(UIImageView *)imageView canceled:(BOOL)canceled
{
    [self refreshImageView];
}

#pragma mark- Tapbar delegate

- (void)deselectTabBarItem:(UITabBar*)tabBar
{
    tabBar.selectedItem = nil;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self performSelector:@selector(deselectTabBarItem:) withObject:tabBar afterDelay:0.2];
    
    switch (item.tag) {
        case 0:
            [self pushedNewBtn];
            break;
        case 1:
            [self pushedEditBtn];
            break;
        case 2:
            [self pushedSaveBtn];
            break;
        default:
            break;
    }
}

#pragma mark- Actionsheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex==actionSheet.cancelButtonIndex){
        return;
    }
    
    UIImagePickerControllerSourceType type = UIImagePickerControllerSourceTypePhotoLibrary;
    
    if([UIImagePickerController isSourceTypeAvailable:type]){
        if(buttonIndex==0 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            type = UIImagePickerControllerSourceTypeCamera;
        }
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.allowsEditing = NO;
        picker.delegate   = self;
        picker.sourceType = type;
        
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma mark- ScrollView

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView.superview;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat Ws = _scrollView.frame.size.width - _scrollView.contentInset.left - _scrollView.contentInset.right;
    CGFloat Hs = _scrollView.frame.size.height - _scrollView.contentInset.top - _scrollView.contentInset.bottom;
    CGFloat W = _imageView.superview.frame.size.width;
    CGFloat H = _imageView.superview.frame.size.height;
    
    CGRect rct = _imageView.superview.frame;
    rct.origin.x = MAX((Ws-W)/2, 0);
    rct.origin.y = MAX((Hs-H)/2, 0);
    _imageView.superview.frame = rct;
}

- (void)resetImageViewFrame
{
    CGSize size = (_imageView.image) ? _imageView.image.size : _imageView.frame.size;
    CGFloat ratio = MIN(_scrollView.frame.size.width / size.width, _scrollView.frame.size.height / size.height);
    CGFloat W = ratio * size.width;
    CGFloat H = ratio * size.height;
    _imageView.frame = CGRectMake(0, 0, W, H);
    _imageView.superview.bounds = _imageView.bounds;
}

- (void)resetZoomScaleWithAnimate:(BOOL)animated
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
    [self scrollViewDidZoom:_scrollView];
}

- (void)refreshImageView
{
    [self resetImageViewFrame];
    [self resetZoomScaleWithAnimate:NO];
}

@end
