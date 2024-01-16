##############################################################################
#
# This file is part of AXP.OS (https://axp.binbash.rocks)
# LICENSE: GPLv3  (https://www.gnu.org/licenses/gpl-3.0.txt)
#
# Copyright (C) 2023 steadfasterX <steadfasterX -AT- gmail #DOT# com>
# Copyright (C) 2024 steadfasterX <steadfasterX -AT- gmail #DOT# com>
#
##############################################################################

DEVICE_PACKAGE_OVERLAYS += \
    vendor/axp/overlays

$(call inherit-product, vendor/axp/axp-vendor.mk)
$(call inherit-product, vendor/extendrom/config/common.mk)

# load the AXP.OS advanced AVB handling
include vendor/axp/BoardConfigVendor.mk
