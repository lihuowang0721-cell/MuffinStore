# fanqiehehe iOS 模拟器实测（借 MuffinStore CI 外壳）
# workflow 执行: gmake clean package → mv packages/*.ipa → 上传 artifact
# 这里把 clean/package 重定义为完整测试编排；产物 packages/result-screenshot.ipa 实为模拟器截图

APP_ID := com.fanqiehehe.harness
SIM := iPhone 16

all: package

clean:
	@rm -rf packages build

package: build/baseline.txt build/injected.txt packages/screenshot-injected.png
	@echo "================= 实测结论 ================="
	@cat build/baseline.txt
	@cat build/injected.txt
	@echo "============================================"

build/baseline.txt build/injected.txt: build/Harness.app/Harness build/fanqiehehe-sim.dylib
	@echo "== 启动模拟器 =="
	@(xcrun simctl boot "$(SIM)" 2>/dev/null || true)
	@xcrun simctl bootstatus "$(SIM)" -b
	@xcrun simctl install "$(SIM)" build/Harness.app
	@echo "== 基线（无注入）=="
	@xcrun simctl launch --terminate-running-process "$(SIM)" $(APP_ID)
	@sleep 3
	@xcrun simctl terminate "$(SIM)" $(APP_ID) 2>/dev/null || true
	@CONT=$$(xcrun simctl get_app_container "$(SIM)" $(APP_ID) data); \
	cp "$$CONT/harness-result.txt" build/baseline.txt; cat build/baseline.txt
	@xcrun simctl io "$(SIM)" screenshot packages/screenshot-baseline.png
	@echo "== 注入（DYLD_INSERT_LIBRARIES）=="
	@DYLIB_ABS=$$(pwd)/build/fanqiehehe-sim.dylib; \
	SIMCTL_CHILD_DYLD_INSERT_LIBRARIES="$$DYLIB_ABS" \
	xcrun simctl launch --terminate-running-process "$(SIM)" $(APP_ID)
	@sleep 3
	@xcrun simctl terminate "$(SIM)" $(APP_ID) 2>/dev/null || true
	@CONT=$$(xcrun simctl get_app_container "$(SIM)" $(APP_ID) data); \
	cp "$$CONT/harness-result.txt" build/injected.txt; cat build/injected.txt

packages/screenshot-injected.png: build/injected.txt
	@xcrun simctl launch --terminate-running-process "$(SIM)" $(APP_ID)
	@sleep 3
	@xcrun simctl io "$(SIM)" screenshot $@
	@xcrun simctl terminate "$(SIM)" $(APP_ID) 2>/dev/null || true
	@cp $@ packages/result-screenshot.ipa
	@echo "== 产物 ==" && ls -la packages/

build/fanqiehehe-sim.dylib: Tweak-sim.x substrate_shim.mm
	@mkdir -p build
	@echo "== Logos 预处理 =="
	@perl "$${THEOS:-$$HOME/theos}/vendor/logos/bin/logos.pl" Tweak-sim.x > build/Tweak-sim.mm
	@echo "== 编译 hook dylib（iphonesimulator SDK, arm64）=="
	@xcrun -sdk iphonesimulator clang++ -arch arm64 -dynamiclib -framework Foundation \
		-fobjc-arc -include substrate_shim.mm \
		-I"$${THEOS:-$$HOME/theos}/vendor/include" \
		build/Tweak-sim.mm -o $@
	@codesign -f -s - $@ && echo DYLIB-SIGNED

build/Harness.app/Harness: test_host_sim.m
	@mkdir -p build/Harness.app
	@echo "== 编译测试宿主 App =="
	@xcrun -sdk iphonesimulator clang -arch arm64 -framework Foundation -framework UIKit \
		-fobjc-arc test_host_sim.m -o $@
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n\
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
<plist version="1.0"><dict>\
<key>CFBundleIdentifier</key><string>$(APP_ID)</string>\
<key>CFBundleName</key><string>Harness</string>\
<key>CFBundleExecutable</key><string>Harness</string>\
<key>CFBundleShortVersionString</key><string>1.0</string>\
<key>CFBundleVersion</key><string>1</string>\
<key>CFBundlePackageType</key><string>APPL</string>\
<key>LSRequiresIPhoneOS</key><true/>\
<key>UIDeviceFamily</key><array><integer>1</integer></array>\
<key>MinimumOSVersion</key><string>17.0</string>\
<key>UILaunchScreen</key><dict/>\
</dict></plist>\n' > build/Harness.app/Info.plist
	@codesign -f -s - build/Harness.app && echo APP-SIGNED
