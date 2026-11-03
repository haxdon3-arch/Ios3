// File: Tweak.x
// Target: Horrorfield iOS (Universal Ad-Skip & Instant Reward Callback)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================================
// 1. AppLovin MAX (MARewardedAd & MAInterstitialAd)
// ============================================================================
%hook MARewardedAd
- (BOOL)isReady {
    return YES;
}
- (void)showAdForPlacement:(NSString *)placement {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            id delegate = [self valueForKey:@"delegate"];
            if (!delegate) return;

            Class rewardClass = objc_getClass("MAReward");
            id rewardObj = nil;
            if (rewardClass && [rewardClass respondsToSelector:@selector(reward)]) {
                rewardObj = [rewardClass performSelector:@selector(reward)];
            }

            if ([delegate respondsToSelector:@selector(didRewardUserForAd:withReward:)]) {
                [delegate performSelector:@selector(didRewardUserForAd:withReward:) withObject:self withObject:rewardObj];
            }
            if ([delegate respondsToSelector:@selector(didHideAd:)]) {
                [delegate performSelector:@selector(didHideAd:) withObject:self];
            }
        } @catch (NSException *e) {}
    });
}
%end

%hook MAInterstitialAd
- (BOOL)isReady {
    return NO; // บล็อกโฆษณาคั่นฉากไม่ให้แสดงขึ้นมา
}
- (void)showAdForPlacement:(NSString *)placement {
    // ข้ามโฆษณาคั่นฉากทันที
}
%end

// ============================================================================
// 2. IronSource (Rewarded Video & Interstitial)
// ============================================================================
%hook IronSource
+ (BOOL)hasRewardedVideo {
    return YES;
}
+ (void)showRewardedVideoWithViewController:(UIViewController *)viewController placement:(NSString *)placementName {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            id delegate = [self valueForKey:@"rewardedVideoDelegate"];
            if (!delegate) return;

            if ([delegate respondsToSelector:@selector(rewardedVideoDidReceiveRewardForPlacement:)]) {
                [delegate performSelector:@selector(rewardedVideoDidReceiveRewardForPlacement:) withObject:placementName];
            }
            if ([delegate respondsToSelector:@selector(rewardedVideoDidClose)]) {
                [delegate performSelector:@selector(rewardedVideoDidClose)];
            }
        } @catch (NSException *e) {}
    });
}
+ (BOOL)hasInterstitial {
    return NO;
}
%end

// ============================================================================
// 3. UnityAds (Rewarded & Non-Rewarded)
// ============================================================================
%hook UnityAds
+ (BOOL)isReady:(NSString *)placementId {
    return YES;
}
+ (void)show:(UIViewController *)viewController placementId:(NSString *)placementId {
    if (!placementId) placementId = @"rewardedVideo";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            id delegate = [self valueForKey:@"delegate"];
            if (delegate && [delegate respondsToSelector:@selector(unityAdsDidFinish:withFinishState:)]) {
                NSMethodSignature *sig = [delegate methodSignatureForSelector:@selector(unityAdsDidFinish:withFinishState:)];
                if (sig) {
                    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                    [inv setTarget:delegate];
                    [inv setSelector:@selector(unityAdsDidFinish:withFinishState:)];
                    [inv setArgument:&placementId atIndex:2];
                    NSInteger completedState = 2; // kUnityAdsFinishStateCompleted
                    [inv setArgument:&completedState atIndex:3];
                    [inv invoke];
                }
            }
        } @catch (NSException *e) {}
    });
}
%end

// ============================================================================
// 4. Google AdMob (GADRewardedAd)
// ============================================================================
%hook GADRewardedAd
- (void)presentFromRootViewController:(UIViewController *)rootViewController
             userDidEarnRewardHandler:(void (^)(void))userDidEarnRewardHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (userDidEarnRewardHandler) {
            userDidEarnRewardHandler();
        }
    });
}
%end
