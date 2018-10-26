//
//  TPKeyboardAvoidingTableView.m
//  TPKeyboardAvoiding
//
//  Created by Michael Tyson on 30/09/2013.
//  Copyright 2015 A Tasty Pixel. All rights reserved.
//

#import "TPKeyboardAvoidingTableView.h"

@interface TPKeyboardAvoidingTableView () <UITextFieldDelegate, UITextViewDelegate>
@end

@implementation TPKeyboardAvoidingTableView

#pragma mark - Setup/Teardown

- (void)setup {
    if ( [self hasAutomaticKeyboardAvoidingBehaviour] ) return;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TPKeyboardAvoiding_keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TPKeyboardAvoiding_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToActiveTextField) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToActiveTextField) name:UITextFieldTextDidBeginEditingNotification object:nil];
    
    self.expandableSections = [NSMutableIndexSet indexSet];
}

-(id)initWithFrame:(CGRect)frame {
    if ( !(self = [super initWithFrame:frame]) ) return nil;
    [self setup];
    return self;
}

-(id)initWithFrame:(CGRect)frame style:(UITableViewStyle)withStyle {
    if ( !(self = [super initWithFrame:frame style:withStyle]) ) return nil;
    [self setup];
    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

-(BOOL)hasAutomaticKeyboardAvoidingBehaviour {
    if ( [self.delegate isKindOfClass:[UITableViewController class]] ) {
        // Theory: Apps built using the iOS 8.3 SDK (probably: older SDKs not tested) seem to handle keyboard
        // avoiding automatically with UITableViewController. This doesn't seem to be documented anywhere
        // by Apple, so results obtained only empirically.
        return YES;
    }

    return NO;
}

-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if ( [self hasAutomaticKeyboardAvoidingBehaviour] ) return;
    [self TPKeyboardAvoiding_updateContentInset];
}

-(void)setContentSize:(CGSize)contentSize {
    if ( [self hasAutomaticKeyboardAvoidingBehaviour] ) {
        [super setContentSize:contentSize];
        return;
    }
	if (CGSizeEqualToSize(contentSize, self.contentSize)) {
		// Prevent triggering contentSize when it's already the same
		// this cause table view to scroll to top on contentInset changes
		return;
	}
    [super setContentSize:contentSize];
    [self TPKeyboardAvoiding_updateContentInset];
}

- (BOOL)focusNextTextField {
    return [self TPKeyboardAvoiding_focusNextTextField];
    
}
- (void)scrollToActiveTextField {
    return [self TPKeyboardAvoiding_scrollToActiveTextField];
}

#pragma mark - Responders, events

-(void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if ( !newSuperview ) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(TPKeyboardAvoiding_assignTextDelegateForViewsBeneathView:) object:self];
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self TPKeyboardAvoiding_findFirstResponderBeneathView:self] resignFirstResponder];
    [super touchesEnded:touches withEvent:event];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ( ![self focusNextTextField] ) {
        [textField resignFirstResponder];
    }
    return YES;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(TPKeyboardAvoiding_assignTextDelegateForViewsBeneathView:) object:self];
    [self performSelector:@selector(TPKeyboardAvoiding_assignTextDelegateForViewsBeneathView:) withObject:self afterDelay:0.1];
}

// Functionality Added by Raj Kr. Sharma

- (void)animatedExpandAndCollapseCellsWithDeletableIndexPaths:(NSArray *)deleteAbleIndexPaths expandabelIndexPaths:(NSArray *)expandabelIndexPaths {
    
    NSMutableArray *deleteArray = [NSMutableArray array];
    NSMutableArray *insertArray = [NSMutableArray array];
    
    NSInteger totalNumberOfSection = [self numberOfSections];
    
    for (NSInteger count = 0; count < totalNumberOfSection; count++) {
        
        NSInteger rows = [self numberOfRowsInSection:count];
        if (rows > 1) {
            
            if ([deleteAbleIndexPaths containsObject:@(count)] && [self.expandableSections containsIndex:count]) {
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:1 inSection:count];
                [deleteArray addObject:tmpIndexPath];
            }
        }
    }
    
    for (NSInteger count = 0; count < totalNumberOfSection; count++) {
        
        NSInteger rows = [self numberOfRowsInSection:count];//[self tableView:self.tableView numberOfRowsInSection:count];
        if (rows < 2) {
            
            if ([expandabelIndexPaths containsObject:@(count)] && ![self.expandableSections containsIndex:count]) {
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:1 inSection:count];
                [insertArray addObject:tmpIndexPath];
            }
        }
    }
    
    
    for (int count = 0; count < deleteAbleIndexPaths.count; count++) {
        [self removeIndex:[[deleteAbleIndexPaths objectAtIndex:count] integerValue]];
        if ([self.expandableSections containsIndex:(NSUInteger)index]) {
            [self.expandableSections removeIndex:(NSUInteger)index];
        }
        
    }
    
    for (int count = 0; count < expandabelIndexPaths.count; count++) {
        [self addIndex:[[expandabelIndexPaths objectAtIndex:count] integerValue]];
        if (![self.expandableSections containsIndex:(NSUInteger)index]) {
            [self.expandableSections addIndex:(NSUInteger)index];
        }
    }
    
    NSMutableArray *reloadableRows = [NSMutableArray array];
    
    for (NSInteger count = 0; count < totalNumberOfSection; count++) {
        [reloadableRows addObject:[NSIndexPath indexPathForRow:0 inSection:count]];
    }

    
    [self beginUpdates];
    
    if (insertArray.count) {
        [self insertRowsAtIndexPaths:insertArray withRowAnimation:UITableViewRowAnimationFade];
    }
    
    if (deleteArray.count) {
        [self deleteRowsAtIndexPaths:deleteArray withRowAnimation:UITableViewRowAnimationFade];
    }
    
    if (reloadableRows.count) {
        [self reloadRowsAtIndexPaths:reloadableRows withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self endUpdates];

}

- (void)addIndex:(NSInteger)index {
    
    if (![self.expandableSections containsIndex:(NSUInteger)index]) {
        [self.expandableSections addIndex:(NSUInteger)index];
    }
    
}

- (void)removeIndex:(NSInteger)index {
    
    if ([self.expandableSections containsIndex:(NSUInteger)index]) {
        [self.expandableSections removeIndex:(NSUInteger)index];
    }
}

@end
