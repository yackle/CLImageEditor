CLImageEditor
===

CLImageEditor provides basic image editing features to iPhone apps. This ViewController is simple to use, and is also possible to incorporate as part of the UIImagePickerController easily.


![sample](CLImageEditorDemo/sample.jpg)


Installing
---

The easiest way to use CLImageEditor is to copy all the files in the CLImageEditor group (or directory) into your app. Add the following frameworks to your project (Build Phases > Link Binary With Libraries): Accelerate, CoreGraphics, CoreImage.

And optional tools are in OptionalImageTools. You might want to add as needed.

##### Or git submodule

Alternatively, you should be able to setup a [git submodule](http://git-scm.com/docs/git-submodule) and reference the files in your Xcode project.

`git submodule add https://github.com/yackle/CLImageEditor.git`

##### Or CocoaPods

[CocoaPods](http://beta.cocoapods.org/) is a dependency manager for Objective-C projects.

`pod 'CLImageEditor'`

or

`pod 'CLImageEditor/AllTools'`

By specifying AllTools subspec, all image tools including optional tools are installed.

#### Optional Image Tools

There are the following optional tools.

`pod 'CLImageEditor/ResizeTool'`

`pod 'CLImageEditor/StickerTool'`



Usage
---
Getting started with CLImageEditor is dead simple. Just initialize it with an UIimage and set a delegate. Then you can use it as a usual ViewController.


```  objc

#import "CLImageEditor.h"

@interface ViewController()
<CLImageEditorDelegate>
@end

- (void)presentImageEditorWithImage:(UIImage*)image
{
    CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:image];
    editor.delegate = self;
	
    [self presentViewController:editor animated:YES completion:nil];
}

```

When used with UIImagePickerController, CLImageEditor can be made to function as a part of the picker by to call the picker's `pushViewController:animated:`.

```  objc

#pragma mark- UIImageController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:image];
    editor.delegate = self;
    
    [picker pushViewController:editor animated:YES];
}

```

After a image has been edited, the editor will call delegate's `imageEditor:didFinishEdittingWithImage:` method. The delegate's method is required to receive edited image.

```  objc


#pragma mark- CLImageEditor delegate

- (void)imageEditor:(CLImageEditor *)editor didFinishEdittingWithImage:(UIImage *)image
{
    _imageView.image = image;
    [editor dismissViewControllerAnimated:YES completion:nil];
}

```

Additionally, the optional delegate's `imageEditorDidCancel:` method is provided for when you want to catch the cancel callback.

For more detail,  please see `CLImageEditorDemo`.


Customizing
---
Icon images are included in `CLImageEditor.bundle`.  You can change the appearance by rewriting the icon images.

Other features for theme settings not yet implemented.


##### Menu customization

Image tools can customize using `CLImageToolInfo`. CLImageEditor's `toolInfo` property has functions to access each tool's info. For example, `subToolInfoWithToolName:recursive:` method is used to get the tool info of a particular name.

```  objc
CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:_imageView.image];
editor.delegate = self;

CLImageToolInfo *tool = [editor.toolInfo subToolInfoWithToolName:@"CLToneCurveTool" recursive:NO];
```

After getting a tool info, by changing its properties, you can customize the image tool on menu view.

```  objc
CLImageToolInfo *tool = [editor.toolInfo subToolInfoWithToolName:@"CLToneCurveTool" recursive:NO];
tool.title = @"TestTitle";
tool.available = NO;     // if available is set to NO, it is removed from the menu view.
tool.dockedNumber = -1;  // Bring to top
//tool.iconImagePath = @"test.png";
```

* `dockedNumber` determines the menu item order. Note that it is simply used as a key for sorting.

The list of tool names can be confirmed with the following code.

```  objc
NSLog(@"%@", editor.toolInfo);
NSLog(@"%@", editor.toolInfo.toolTreeDescription);
```


License
---
CLImageEditor is released under the MIT License, see [LICENSE](LICENSE).