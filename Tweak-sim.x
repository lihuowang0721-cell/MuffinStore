/* Tweak.x 的 macOS 测试变体：去掉 UIKit 依赖的 hook，保留 Foundation 可验证的 VIP+广告逻辑
 * 与 iOS 版 Tweak.x 同源，仅适配 macOS 测试环境 */
#import <Foundation/Foundation.h>

// TG频道：https://t.me/iosrxwy/

%hook SSAccountInfo
- (_Bool)isVip {
    return YES;
}
%end

%hook SSVipInfo
// VIP剩余时间
- (id)leftTime {
    return [NSString stringWithFormat:@"%.0lf", 2534308005 - [[NSDate date] timeIntervalSince1970]];
}

// VIP到期时间,20990113
- (id)expireTime {
    return @"4071916800";
}

- (id)isVip {
    return @"1";
}
%end

// 顺便解锁番茄畅听等
%hook SSUser
- (bool)isVip {
    return 1;
}
%end

%hook BUSplashAdView
- (void)setSlot:(id)arg1 {
    // 吞掉广告槽位设置，不调用 %orig
}
%end
