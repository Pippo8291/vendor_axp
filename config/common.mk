##############################################################################
#
# This file is part of AXP.OS (https://axpos.org)
# LICENSE: GPLv3  (https://www.gnu.org/licenses/gpl-3.0.txt)
#
# Copyright (C) 2023-2025 steadfasterX <steadfasterX -AT- gmail #DOT# com>
#
##############################################################################

$(call inherit-product, vendor/axp/axp-vendor.mk)

# use correct overlay based on android SDK
ifeq ($(call math_gt_or_eq,$(PLATFORM_SDK_VERSION),31), true)
DEVICE_PACKAGE_OVERLAYS += \
    vendor/axp/overlays
else ifeq ($(call math_gt_or_eq,$(PLATFORM_SDK_VERSION),30), true)
DEVICE_PACKAGE_OVERLAYS += \
    vendor/axp/overlays-11
else ifeq ($(call math_gt_or_eq,$(PLATFORM_SDK_VERSION),28), true)
DEVICE_PACKAGE_OVERLAYS += \
    vendor/axp/overlays-10
endif

# include https://github.com/sfX-android/android_vendor_extendrom
$(call inherit-product, vendor/extendrom/config/common.mk)

include vendor/axp/BoardConfigVendor.mk
