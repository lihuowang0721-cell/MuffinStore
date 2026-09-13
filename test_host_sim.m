/* iOS 模拟器测试宿主：App 启动时评估 hook 效果
 * 结果写沙盒文件 harness-result.txt + 渲染到屏幕（供截图存证） */
#import <UIKit/UIKit.h>

@interface SSAccountInfo : NSObject
- (BOOL)isVip;
@end
@implementation SSAccountInfo
- (BOOL)isVip { return NO; }
@end

@interface SSVipInfo : NSObject
- (id)expireTime;
- (id)leftTime;
- (id)isVip;
@end
@implementation SSVipInfo
- (id)expireTime { return @"0"; }
- (id)leftTime { return @"0"; }
- (id)isVip { return @"0"; }
@end

@interface SSUser : NSObject
- (BOOL)isVip;
@end
@implementation SSUser
- (BOOL)isVip { return NO; }
@end

static BOOL injected(void) {
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    return [env[@"DYLD_INSERT_LIBRARIES"] length] > 0;
}

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    SSAccountInfo *acc = [SSAccountInfo new];
    SSVipInfo *vip = [SSVipInfo new];
    SSUser *user = [SSUser new];

    BOOL accVip = [acc isVip];
    NSString *vipFlag = [vip isVip];
    NSString *expire = [vip expireTime];
    NSString *left = [vip leftTime];
    BOOL userVip = [user isVip];

    BOOL hooked = accVip && userVip && [vipFlag isEqualToString:@"1"] && [expire isEqualToString:@"4071916800"];

    NSMutableString *r = [NSMutableString string];
    [r appendFormat:@"SSAccountInfo.isVip  = %d\n", accVip];
    [r appendFormat:@"SSVipInfo.isVip      = %@\n", vipFlag];
    [r appendFormat:@"SSVipInfo.expireTime = %@\n", expire];
    [r appendFormat:@"SSVipInfo.leftTime   = %@\n", left];
    [r appendFormat:@"SSUser.isVip         = %d\n", userVip];
    [r appendFormat:@"HOOKED = %@\n", hooked ? @"YES ✅ (去广告+SVIP 生效)" : @"NO ❌ (未生效/基线)"];

    NSString *dst = [NSTemporaryDirectory() stringByAppendingPathComponent:@"harness-result.txt"];
    [r writeToFile:dst atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *home = NSHomeDirectory();
    [r writeToFile:[home stringByAppendingPathComponent:@"harness-result.txt"]
        atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"HARNESS-RESULT:\n%@", r);

    UIWindow *w = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    w.backgroundColor = hooked ? [UIColor colorWithRed:0.1 green:0.5 blue:0.2 alpha:1]
                               : [UIColor colorWithRed:0.5 green:0.1 blue:0.1 alpha:1];
    UILabel *lb = [[UILabel alloc] initWithFrame:w.bounds];
    lb.numberOfLines = 0;
    lb.textColor = UIColor.whiteColor;
    lb.font = [UIFont monospacedSystemFontOfSize:15 weight:UIFontWeightBold];
    lb.text = [NSString stringWithFormat:@"fanqiehehe 模拟器实测\n(DYLD 注入: %@)\n\n%@",
               injected() ? @"已开启" : @"关闭", r];
    lb.center = w.center;
    lb.textAlignment = NSTextAlignmentCenter;
    [w addSubview:lb];
    w.rootViewController = [UIViewController new];
    [w makeKeyAndVisible];
    self.window = w;
    return YES;
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
