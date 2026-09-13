/* Substrate 兼容垫片：用 ObjC Runtime 实现 MSHookMessageEx
 * 使 Logos 生成的 hook 代码在 macOS/iOS 模拟器上无需 CydiaSubstrate 即可运行
 * 注意：必须 extern "C"，与 shim-include/substrate.h 的声明保持一致 */
#import <objc/runtime.h>
#import <objc/message.h>
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

void MSHookMessageEx(Class cls, SEL sel, IMP newImp, IMP *origOut) {
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) {
        m = class_getClassMethod(cls, sel);
    }
    if (!m) return;
    if (origOut) *origOut = method_getImplementation(m);
    method_setImplementation(m, newImp);
}

#ifdef __cplusplus
}
#endif
