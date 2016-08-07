//
//  UILabel+Copy.m
//
//  Created by Haoyipeng on 16/8/1.
//
//

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
    return [objc_getAssociatedObject(self, @selector(numberToSwitchCopy)) boolValue];
}

- (void)setNumberToSwitchCopy:(NSNumber *)number {
    objc_setAssociatedObject(self, @selector(numberToSwitchCopy), [NSNumber numberWithBool:number], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self attachTapHandler];
}

- (NSNumber *)numberToSwitchCopy {
    return objc_getAssociatedObject(self, @selector(numberToSwitchCopy));
}

@end
