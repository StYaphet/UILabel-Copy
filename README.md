#一行代码为UILabel添加长按复制功能
最近在项目新版本的开发过程中遇到这样一个需求，要为UILabel添加复制功能，社区的楼主发帖内容，评论内容等都可以复制。

一开始我的想法是创建一个UILabel的子类，为这个子类添加复制功能，然后让社区模块中所有的UILabel都继承自这个有复制功能的UILabel子类CopyableLabel，就可以实现复制了。可是在看了代码之后我发现，这样做是行不通的，因为社区中用到了好多类型的UILabel，并不都是直接继承自UILabel的，有的是继承自其他封装好的子类，比如说NIAtrributedLabel等，这样就没有办法让他们都继承CopyableLabel。

之后有个想法是定义一个CopyableLabel的协议，让社区中所有类型的Label都遵守这个CopyableLabel协议，但是这样的话，需要在所有类型的Label中都添加重复的代码，重用性不太好。

最终，在与同事讨论之后想到了这样一个办法，直接写一个UILabel的分类UILabel+Copy，在分类中添加一个BOOL类型的属性，当设置这个属性为YES的时候，即为UILabel开启复制的功能。

#How
废话不多说，我们直接上代码：

UILabel+Copy.h
.h文件里边的内容很简单，就是为UILabel添加一个属性

	@interface UILabel (Copy)
	
	@property (nonatomic,strong) NSNumber *numberToSwitchCopy;
	
	@end
	
UILabel+Copy.m

	#import "UILabel+Copy.h"

	@implementation UILabel (Copy)

	- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copyText:));
	}

	- (void)attachTapHandler {
    self.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:g];
	}

	//  处理手势相应事件
	- (void)handleTap:(UIGestureRecognizer *)g {
    [self becomeFirstResponder];
    
    UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(copyText:)];
    [[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObject:item]];
    [[UIMenuController sharedMenuController] setTargetRect:self.frame inView:self.superview];
    [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
    
	}

	//  复制时执行的方法
	- (void)copyText:(id)sender {
    //  通用的粘贴板
    UIPasteboard *pBoard = [UIPasteboard generalPasteboard];
    //  因为有时候 label 中设置的是attributedText
    //  而 UIPasteboard 的string只能接受 NSString 类型
    //  所以要做相应的判断
    
    if (objc_getAssociatedObject(self, @"replyContent")) {
        pBoard.string = objc_getAssociatedObject(self, @"replyContent");
    } else {
        if (self.text) {
            pBoard.string = self.text;
        } else {
            pBoard.string = self.attributedText.string;
        }
    }
	}

	- (BOOL)canBecomeFirstResponder {
    return [objc_getAssociatedObject(self, @selector(numberToSwitchFirstResponder)) boolValue];
	}

	- (void)setNumberToSwitchFirstResponder:(NSNumber *)number {
    objc_setAssociatedObject(self, @selector(numberToSwitchFirstResponder), [NSNumber numberWithBool:number], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self attachTapHandler];
	}

	- (NSNumber *)numberToSwitchFirstResponder {
    return objc_getAssociatedObject(self, @selector(numberToSwitchFirstResponder));
	}

	@end
	
在需要使用复制功能的时候只需要写这样一行代码：
`xxxLabel.numberToSwitchCopy = @1`，
试一下，你就会发现你的UILabel同样拥有复制功能啦。

#why
贴完了代码，讲完了用法，我们来详细看一看这些代码为什么要这么写：

首先我们知道UILabel是不支持复制这个功能的，经查询，系统中支持复制功能的控件有如下3种：

* UITextView
* UITextField
* UIWebView

所以要想让UILabel支持复制功能，那么我们就必须自己想办法。

因为是要长按复制弹出来的东西是一个UIMenuController，所以我们要为UILabel添加一个长按的手势识别（UILongPressGestureRecognizer），并在系统识别出这个手势之后为其添加相应的动作（action）。

在这之前，我们需要使UILabel能成为第一响应者，不过应该注意的是，并不是所有的UILabel都能成为第一响应这，所以我们写覆写`canBecomeFirstResponder`方法的时候采取的做法是，首先取得UILabel的关联对象`numberToSwitchCopy`的布尔值，利用这个布尔值来决定UILabel是否能成为第一响应者，没有设置这个关联对象的UILabel是不能成为第一响应者的。

在系统识别出长按动作之后，执行`handleTap:`这个方法，在这个方法中，使UILabel成为第一响应者（UIMenuController的要求，要显示UIMenuController对象的UIView必须是当前UIWindow的第一响应者），然后为UIMenuController设置一组UIMenuItem对象，然后设置显示区域，最后将UIMenuController设置为可见。上述代码中的`handleTap:`方法即完成了这些操作，使UIMenuController显示出来。

同时，如果只是在UIMenuItem的action中写了方法名但是没有真正实现action方法的时候UIMenuController也是不能显示的（UIMenuController会在显示前枚举所有的UIMenuItem对象，并检查第一响应者有没有实现指定的动作方法，如果没有实现该方法，UIMenuController就不会显示相应的UIMenuItem对象）。还需要注意一点的是，当你明确需要在UIMenuController上显示的文字是“复“”制的时候，`copyText:`可以换成其他的方法名，但是不要写成`copy`，因为这会使系统的*拷贝*这个UIMenuItem显示出来（系统默认为我们添加的UIMenuItem），而我们希望在UIMenuController上显示的文字是“复制”而不是“拷贝”。

在`copyText:`方法中我们完成将选中的文字复制到系统的粘贴板中，首先获取系统的粘贴板` UIPasteboard *pBoard = [UIPasteboard generalPasteboard];`，然后将所需复制的文字赋值给`pBoard`的`String`属性。值得注意的是`pBoard`的`String`属性只能接受NSString类型的值，所以如果你的UILabel中的文字其实是NSAtrributedString，就要转换成NSString。

稍后我会把UILabel+Copy.h的代码放到GitHub上去，希望大家多多提出意见，可以使UILabel+Copy这个分类变得更好用。