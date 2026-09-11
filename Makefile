TARGET = iphone:clang:14.5:14.0
ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = Dragon Reading Eggplant XSFM

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = fanqiehehe

fanqiehehe_FILES = Tweak.x
fanqiehehe_CFLAGS = -fobjc-arc -fno-modules

after-package::
	cp packages/*.deb packages/fanqiehehe.ipa

include $(THEOS_MAKE_PATH)/tweak.mk
