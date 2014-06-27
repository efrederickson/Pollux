ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:7.1:7.1
#CFLAGS = -fobjc-arc <- causes image to fail sending properly

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Pollux
Pollux_FILES = Tweak.xm MBProgressHUD.m
Pollux_FRAMEWORKS = UIKit
Pollux_PRIVATE_FRAMEWORKS = ChatKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSMS Preferences"
SUBPROJECTS += polluxsettings
include $(THEOS_MAKE_PATH)/aggregate.mk
