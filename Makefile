TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = InstantNoAds
InstantNoAds_FILES = Tweak.x
InstantNoAds_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
InstantNoAds_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/tweak.mk
