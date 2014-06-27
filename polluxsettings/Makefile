ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest:latest
CFLAGS = -fobjc-arc
LDFLAGS = -F$(THEOS)/frameworks

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PolluxSettings
PolluxSettings_FILES = PolluxSettings.mm
PolluxSettings_INSTALL_PATH = /Library/PreferenceBundles
PolluxSettings_FRAMEWORKS = UIKit SettingsKit CoreGraphics
PolluxSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PolluxSettings.plist$(ECHO_END)
