/* 自带 substrate 声明：避免依赖 theos vendor 的 CydiaSubstrate 头链
 * 实现见 substrate_shim.mm（基于 ObjC Runtime，无需 CydiaSubstrate 动态库） */
#pragma once

#import <objc/objc.h>
#import <objc/runtime.h>

#ifdef __cplusplus
extern "C" {
#endif

void MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old);

#ifdef __cplusplus
}
#endif
