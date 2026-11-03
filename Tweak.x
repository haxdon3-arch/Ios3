// File: Tweak.x
// Target: Horrorfield iOS (Universal Ad-Skip & Instant Reward - Clean Compile Build)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ============================================================================
// ประกาศ @interface สืบทอดจาก NSObject ครบทุกคลาส ป้องกัน Forward Declaration Error
// ============================================================================
@interface MARewardedAd : NSObject
@end

@interface MAInterstitialAd : NSObject
@end

@interface IronSource : NSObject
@end

@interface UnityAds : NSObject
@end

@interface GADRewardedAd : NSObject
@end

// ============================================================================
// 1. AppLovin MAX (MARewardedAd & MAInterstitialAd)
// ============================================================================
%hook MARewardedAd
- (BOOL)isReady {
    return YES;
}
- (void)showAdForPlacement:(id)placement {
    id selfRef = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            id delegate = [selfRef valueForKey:@"delegate"];
            if (!delegate) return;

            Class rewardClass = objc_getClass("MAReward");
            id rewardObj = nil;
            SEL rewardSel = NSSelectorFromString(@"reward");
            if (rewardClass && [rewardClass respondsToSelector:rewardSel]) {
                rewardObj = ((id (*)(id, SEL))objc_msgSend)(rewardClass, rewardSel);
            }

            SEL didRewardSel = NSSelectorFromString(@"didRewardUserForAd:withReward:");
            if ([delegate respondsToSelector:didRewardSel]) {
                ((void (*)(id, SEL, id, id))objc_msgSend)(delegate, didRewardSel, selfRef, rewardObj);
            }

            SEL didHideSel = NSSelectorFromString(@"didHideAd:");
            if ([delegate respondsToSelector:didHideSel]) {
                ((void (*)(id, SEL, id))objc_msgSend)(delegate, didHideSel, selfRef);
            }
        } @catch (NSException *e) {}
    });
}
%end

%hook MAInterstitialAd
- (BOOL)isReady {
    return NO;
}
- (void)showAdForPlacement:(id)placement {
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
+ (void)showRewardedVideoWithViewController:(id)viewController placement:(id)placementName {
    id classRef = self;
    id safePlacement = placementName;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            id delegate = [classRef valueForKey:@"rewardedVideoDelegate"];
            if (!delegate) return;

            SEL receiveRewardSel = NSSelectorFromString(@"rewardedVideoDidReceiveRewardForPlacement:");
            if ([delegate respondsToSelector:receiveRewardSel]) {
                ((void (*)(id, SEL, id))objc_msgSend)(delegate, receiveRewardSel, safePlacement);
            }

            SEL closeSel = NSSelectorFromString(@"rewardedVideoDidClose");
            if ([delegate respondsToSelector:closeSel]) {
                ((void (*)(id, SEL))objc_msgSend)(delegate, closeSel);
            }
        } @catch (NSException *e) {}
    });
}
+ (BOOL)hasInterstitial {
    return NO;
}
%end

// ============================================================================
// 3. UnityAds (Rewarded & Non-Rewarded) — ใช้ objc_msgSend ตรง ตัดปัญหา NSInvocation const pointer
// ============================================================================
%hook UnityAds
+ (BOOL)isReady:(NSString *)placementId {
    return YES;
}
+ (void)show:(UIViewController *)viewController placementId:(NSString *)placementId {
    id classRef = self;
    NSString *safePlacement = placementId ? [placementId copy] : @"rewardedVideo";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            id delegate = [classRef valueForKey:@"delegate"];
            if (!delegate) return;

            // UnityAds 3.x delegate: unityAdsDidFinish:withFinishState: (State 2 = Completed)
            SEL finishSel = NSSelectorFromString(@"unityAdsDidFinish:withFinishState:");
            if ([delegate respondsToSelector:finishSel]) {
                ((void (*)(id, SEL, NSString *, NSInteger))objc_msgSend)(delegate, finishSel, safePlacement, 2);
            }

            // UnityAds 4.x delegate: unityAdsShowComplete:withFinishState: (State 1 = Completed)
            SEL showCompleteSel = NSSelectorFromString(@"unityAdsShowComplete:withFinishState:");
            if ([delegate respondsToSelector:showCompleteSel]) {
                ((void (*)(id, SEL, NSString *, NSInteger))objc_msgSend)(delegate, showCompleteSel, safePlacement, 1);
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
