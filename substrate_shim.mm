/* Substrate 兼容垫片：用 ObjC Runtime 实现 MSHookMessageEx
 * 使 Logos 生成的 hook 代码在 macOS 上无需 CydiaSubstrate 即可运行 */
#import <objc/runtime.h>
#import <objc/message.h>
#import <Foundation/Foundation.h>

typedef IMP (*MSHookMessageExFunc)(Class, SEL, IMP, IMP *);

void MSHookMessageEx(Class cls, SEL sel, IMP newImp, IMP *origOut) {
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) {
        // 类方法兜底
        m = class_getClassMethod(cls, sel);
    }
    if (!m) return;
    if (origOut) *origOut = method_getImplementation(m);
    method_setImplementation(m, newImp);
}
