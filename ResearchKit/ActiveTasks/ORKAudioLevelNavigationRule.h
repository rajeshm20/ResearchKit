/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
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

#import "ORKStepNavigationRule.h"

NS_ASSUME_NONNULL_BEGIN

@interface ORKAudioLevelNavigationRule : ORKStepNavigationRule

/**
 Returns an initialized direct-step navigation rule using the specified destination step identifier.
 
 @param audioLevelStepIdentifier   The identifier of the step with the audio file to check.
 @param defaultStepIdentifier   The identifier of the destination step if audio test passes.
 
 @return A audio level step navigation rule.
 */
- (instancetype)initWithAudioLevelStepIdentifier:(NSString *)audioLevelStepIdentifier
                           defaultStepIdentifier:(NSString *)defaultStepIdentifier NS_DESIGNATED_INITIALIZER;

/**
 Returns a new direct-step navigation rule initialized from data in a given unarchiver.
 
 @param aDecoder    The coder from which to initialize the step navigation rule.
 
 @return A new direct-step navigation rule.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy, readonly) NSString *audioLevelStepIdentifier;
@property (nonatomic, copy, readonly) NSString *defaultStepIdentifier;

@end

NS_ASSUME_NONNULL_END
