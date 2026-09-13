#!/bin/bash
# 从可用设备里挑一台 iPhone 模拟器，输出 UDID
UDID=$(python3 - << 'PYEOF'
import json, subprocess
out = subprocess.check_output(["xcrun", "simctl", "list", "devices", "-j", "available"]).decode()
d = json.loads(out)
for runtime, devices in d.get("devices", {}).items():
    for dev in devices:
        if dev.get("isAvailable") and "iPhone" in dev.get("name", ""):
            print(dev["udid"])
            raise SystemExit
PYEOF
)
if [ -n "$UDID" ]; then
  echo "$UDID"
else
  echo "iPhone 16"
fi
