#import <ChatInputTextViewImpl/ChatInputTextViewImpl.h>

@implementation ChatInputTextViewImplTargetForAction

- (instancetype)initWithTarget:(id _Nullable)target {
    self = [super init];
    if (self != nil) {
        _target = target;
    }
    return self;
}

@end

@implementation ChatInputTextViewImpl

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (_targetForActionImpl) {
        ChatInputTextViewImplTargetForAction *result = _targetForActionImpl(action);
        if (result) {
            return result.target != nil;
        }
    }
    
    if (action == @selector(paste:)) {
        NSArray *items = [UIMenuController sharedMenuController].menuItems;
        if (((UIMenuItem *)items.firstObject).action == @selector(toggleBoldface:)) {
            return false;
        }
        return true;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    static SEL promptForReplaceSelector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        promptForReplaceSelector = NSSelectorFromString(@"_promptForReplace:");
    });
    if (action == promptForReplaceSelector) {
        return false;
    }
#pragma clang diagnostic pop
    
    if (action == @selector(toggleUnderline:)) {
        return false;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (id)targetForAction:(SEL)action withSender:(id)__unused sender
{
    if (_targetForActionImpl) {
        ChatInputTextViewImplTargetForAction *result = _targetForActionImpl(action);
        if (result) {
            return result.target;
        }
    }
    return [super targetForAction:action withSender:sender];
}

- (void)copy:(id)sender {
    if (_shouldCopy == nil || _shouldCopy()) {
        [super copy:sender];
    }
}

- (void)paste:(id)sender
{
    if (_shouldPaste == nil || _shouldPaste()) {
        [super paste:sender];
    }
}

- (NSArray *)keyCommands {
    UIKeyCommand *plainReturn = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:kNilOptions action:@selector(handlePlainReturn:)];
    return @[
        plainReturn
    ];
}

- (void)handlePlainReturn:(id)__unused sender {
    if (_shouldReturn) {
        _shouldReturn();
    }
}

- (void)deleteBackward {
    bool notify = self.text.length == 0;
    [super deleteBackward];
    if (notify) {
        if (_backspaceWhileEmpty) {
            _backspaceWhileEmpty();
        }
    }
}

@end