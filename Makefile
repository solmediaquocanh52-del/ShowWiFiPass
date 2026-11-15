TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Preferences SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ShowWiFiPass
ShowWiFiPass_FILES = Tweak.x
ShowWiFiPass_CFLAGS = -fobjc-arc
ShowWiFiPass_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
