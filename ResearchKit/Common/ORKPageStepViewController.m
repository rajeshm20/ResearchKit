/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKPageStepViewController.h"
#import <ResearchKit/ResearchKit_Private.h>
#import "ORKStepViewController_Internal.h"
#import "UIBarButtonItem+ORKBarButtonItem.h"
#import "ORKHelpers.h"
#import "ORKTaskViewController_Internal.h"

@implementation ORKPageStepViewController

- (void)updatePageIndices {
    // do nothing. subclasses can override
}

- (UIViewController *)viewControllerForPageIndex:(id <NSCopying, NSCoding, NSObject>)pageIndex {
    // Required override
    NSAssert(false, @"Abstract method -viewControllerForPageIndex: Not implemented.");
    return nil;
}

- (UIScrollView*)registeredScrollViewForViewController:(UIViewController*)viewController {
    
    
    // By default, there is no scrollview to register
    return nil;
}

- (void)stepDidChange {
    if (![self isViewLoaded]) {
        return;
    }
    
    _currentPageIndex = NSNotFound;
    [self updatePageIndices];
    
    [self goToPage:0 animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Prepare pageViewController
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                          navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                        options:nil];
    _pageViewController.delegate = self;
    
    if ([_pageViewController respondsToSelector:@selector(edgesForExtendedLayout)]) {
        _pageViewController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    _pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _pageViewController.view.frame = self.view.bounds;
    [self.view addSubview:_pageViewController.view];
    [self addChildViewController:_pageViewController];
    [_pageViewController didMoveToParentViewController:self];
    
    [self stepDidChange];
}

- (UIBarButtonItem *)goToPreviousPageButtonItem {
    UIBarButtonItem *button = [UIBarButtonItem ork_backBarButtonItemWithTarget:self action:@selector(goToPreviousPage)];
    button.accessibilityLabel = ORKLocalizedString(@"AX_BUTTON_BACK", nil);
    return button;
}

- (void)updateNavLeftBarButtonItem {
    if (_currentPageIndex == 0) {
        [super updateNavLeftBarButtonItem];
    } else {
        self.navigationItem.leftBarButtonItem = [self goToPreviousPageButtonItem];
    }
}

- (void)updateBackButton {
    if (_currentPageIndex == NSNotFound) {
        return;
    }
    
    [self updateNavLeftBarButtonItem];
}

- (void)goToPreviousPage {
    [self navigateDelta:-1];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (UIViewController *)viewControllerForIndex:(NSUInteger)index {
    if (index >= _pageIndices.count) {
        return nil;
    }
    return [self viewControllerForPageIndex:self.pageIndices[index]];
}

#pragma mark ORKStepViewControllerDelegate

- (void)stepViewController:(ORKStepViewController *)stepViewController didFinishWithNavigationDirection:(ORKStepViewControllerNavigationDirection)direction {
    if (_currentPageIndex == NSNotFound) {
        return;
    }
    
    NSInteger delta = (direction == ORKStepViewControllerNavigationDirectionForward) ? 1 : -1;
    [self navigateDelta:delta];
}

- (void)stepViewControllerResultDidChange:(ORKStepViewController *)stepViewController {
    [self notifyDelegateOnResultChange];
}

- (void)stepViewControllerDidFail:(ORKStepViewController *)stepViewController withError:(NSError *)error {
    STRONGTYPE(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(stepViewControllerDidFail:withError:)]) {
        [delegate stepViewControllerDidFail:self withError:error];
    }
}

- (BOOL)stepViewControllerHasNextStep:(ORKStepViewController *)stepViewController {
    if (_currentPageIndex < (_pageIndices.count - 1)) {
        return YES;
    }
    return [self hasNextStep];
}

- (BOOL)stepViewControllerHasPreviousStep:(ORKStepViewController *)stepViewController {
    return [self hasPreviousStep];
}

- (void)stepViewController:(ORKStepViewController *)stepViewController recorder:(ORKRecorder *)recorder didFailWithError:(NSError *)error {
    STRONGTYPE(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(stepViewController:recorder:didFailWithError:)]) {
        [delegate stepViewController:self recorder:recorder didFailWithError:error];
    }
}

- (void)stepViewControllerWillAppear:(ORKStepViewController *)stepViewController {
    // do nothing. Implement so that overrides can call through to super.
}

#pragma mark Navigation

- (void)navigateDelta:(NSInteger)delta {
    // Entry point for forward/back navigation.
    NSUInteger pageCount = _pageIndices.count;
    
    if (_currentPageIndex == 0 && delta < 0) {
        // Navigate back in our parent task VC.
        [self goBackward];
    } else if (_currentPageIndex >= (pageCount - 1) && delta > 0) {
        // Navigate forward in our parent task VC.
        [self goForward];
    } else {
        // Navigate within our managed steps
        [self goToPage:(_currentPageIndex + delta) animated:YES];
    }
}

- (void)goToPage:(NSInteger)page animated:(BOOL)animated {
    UIViewController *viewController = [self viewControllerForIndex:page];
    
    if (!viewController) {
        ORK_Log_Debug(@"No view controller!");
        return;
    }
    
    // Set self as the delegate if this is a step view controller and the delegate is not already set
    if ([viewController isKindOfClass:[ORKStepViewController class]]) {
        ORKStepViewController *stepViewController = (ORKStepViewController*)viewController;
        if (stepViewController.delegate == nil) {
            stepViewController.delegate = self;
        }
    }
    
    NSUInteger currentIndex = _currentPageIndex;
    if (currentIndex == NSNotFound) {
        animated = NO;
    }
    
    UIPageViewControllerNavigationDirection direction = (!animated || page > currentIndex) ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    ORKAdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    _currentPageIndex = page;
    __weak typeof(self) weakSelf = self;
    
    //unregister ScrollView to clear hairline
    [self.taskViewController setRegisteredScrollView:nil];
    
    [self.pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:^(BOOL finished) {
        if (finished) {
            STRONGTYPE(weakSelf) strongSelf = weakSelf;
            [strongSelf updateBackButton];
            
            //register ScrollView to update hairline
            UIScrollView *registeredScrollView = [strongSelf registeredScrollViewForViewController:viewController];
            [strongSelf.taskViewController setRegisteredScrollView:registeredScrollView];
            
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, strongSelf.navigationItem.leftBarButtonItem);
        }
    }];
}

#pragma mark - UIStateRestoring

static NSString *const _ORKCurrentPageIndexRestoreKey = @"currentPageIndex";
static NSString *const _ORKPageIndicesKey = @"pageIndices";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_pageIndices forKey:_ORKPageIndicesKey];
    [coder encodeInteger:_currentPageIndex forKey:_ORKCurrentPageIndexRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _currentPageIndex = [coder decodeIntegerForKey:_ORKCurrentPageIndexRestoreKey];
    _pageIndices = [coder decodeObjectOfClass:[NSArray class] forKey:_ORKPageIndicesKey];
    
    [self goToPage:_currentPageIndex animated:NO];
}

@end
