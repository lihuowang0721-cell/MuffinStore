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
	@mkdir -p packages
	@xcrun simctl bootstatus "$(SIM)" -b
	@xcrun simctl launch --terminate-running-process "$(SIM)" $(APP_ID)
	@sleep 5
	@for i in 1 2 3; do \
		xcrun simctl io "$(SIM)" screenshot $@ && break || sleep 3; \
	done
	@xcrun simctl terminate "$(SIM)" $(APP_ID) 2>/dev/null || true
	@test -s $@ && echo "SCREENSHOT-OK: $@"
	@cp $@ packages/result-screenshot.ipa
	@echo "== 产物 ==" && ls -la packages/

build/fanqiehehe-sim.dylib: Tweak-sim.x substrate_shim.mm
	@mkdir -p build
	@echo "== Logos 预处理 =="
	@perl "$${THEOS:-$$HOME/theos}/vendor/logos/bin/logos.pl" Tweak-sim.x > build/Tweak-sim.mm
	@echo "== 编译 hook dylib（iphonesimulator SDK, arm64）=="
	@xcrun -sdk iphonesimulator clang++ -arch arm64 -dynamiclib -framework Foundation \
		-fobjc-arc -Ishim-include \
		build/Tweak-sim.mm substrate_shim.mm -o $@
	@codesign -f -s - $@ && echo DYLIB-SIGNED

build/Harness.app/Harness: test_host_sim.m Info-Harness.plist
	@mkdir -p build/Harness.app
	@echo "== 编译测试宿主 App =="
	@xcrun -sdk iphonesimulator clang -arch arm64 -framework Foundation -framework UIKit \
		-fobjc-arc test_host_sim.m -o $@
	@cp Info-Harness.plist build/Harness.app/Info.plist
	@plutil -lint build/Harness.app/Info.plist
	@codesign -f -s - build/Harness.app && echo APP-SIGNED
