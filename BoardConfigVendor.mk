#########################################################################################################
#
# This file is part of AXP.OS (https://axpos.org)
# LICENSE: GPLv3 (https://www.gnu.org/licenses/gpl-3.0.txt)
#
# Copyright (C) 2023-2025 steadfasterX <steadfasterX -AT- gmail #DOT# com>
#
#########################################################################################################
# AXP.OS advanced AVB handling
#
# verification:
# $> external/avb/avbtool info_image --image vbmeta.img
# $> external/avb/avbtool verify_image --follow_chain_partitions --image vbmeta.img
#########################################################################################################
#
# !!!!!!!! IMPORTANT !!!!!!!!!!
#
# in order to make use of the required conditions this BoardConfig must be explicitly
# included in the target's own BoardConfig.mk - at the bottom (must be the last line)!
# Here a copy template for the device tree:
#
# # even though we include vendor/axp/config/common.mk we need to include BoardConfig (after the above
# # definitions & includes), too so we we can make use of the conditions within
# include vendor/axp/BoardConfigVendor.mk
#
#########################################################################################################

# Enable android verified boot
BOARD_AVB_ENABLE := true

# AVB key size and hash
BOARD_AVB_ALGORITHM := SHA512_RSA4096

# pub key (avb_pkmd.bin) must be flashed to avb_custom_key partition
# see https://axpos.org/Bootloader-Lock
BOARD_AVB_KEY_PATH := user-keys/avb.pem

# BOARD_AVB_RECOVERY_KEY_PATH must be defined for if non-A/B is supported. e.g. klte
# See https://android.googlesource.com/platform/external/avb/+/master/README.md#booting-into-recovery
ifeq ($(TARGET_OTA_ALLOW_NON_AB),true)
ifneq ($(INSTALLED_RECOVERYIMAGE_TARGET),)
BOARD_AVB_RECOVERY_KEY_PATH := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1
endif
endif

# overwrite testkeys on system partition if defined (e.g. FP3)
ifdef BOARD_AVB_SYSTEM_KEY_PATH
BOARD_AVB_SYSTEM_KEY_PATH := $(BOARD_AVB_KEY_PATH)
endif

# board algorithms
BOARD_AVB_BOOT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_RECOVERY_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_SYSTEM_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VENDOR_BOOT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VENDOR_DLKM_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_DTBO_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_INIT_BOOT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_ODM_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_ODM_DLKM_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_PRODUCT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_PVMFW_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_SYSTEM_DLKM_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_SYSTEM_EXT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_SYSTEM_OTHER_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VENDOR_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VENDOR_KERNEL_BOOT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
CUSTOM_IMAGE_AVB_ALGORITHM := $(BOARD_AVB_ALGORITHM)

# enable for troublehshooting vbmeta digest:
# (do not set on productive builds)
#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag
#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flag 2

# Using either sha256 or sha512 for the hashtree of all partitions depending on the device performance
ifdef AXP_LOWEND_DEVICE
TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM := sha256
else
TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM := sha512
endif

# overwrite general hashtree algorithms
TARGET_AVB_SYSTEM_HASHTREE_ALGORITHM := $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
TARGET_AVB_SYSTEM_OTHER_HASHTREE_ALGORITHM := $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
TARGET_AVB_SYSTEM_EXT_HASHTREE_ALGORITHM := $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
TARGET_AVB_SYSTEM_DLKM_HASHTREE_ALGORITHM := $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)

# enforce global hashtree footer algorithm for system
BOARD_AVB_SYSTEM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)

# if required, enforce global hash footer algorithm for vendor_boot
ifdef BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE
BOARD_AVB_VENDOR_BOOT_ADD_HASH_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
endif

# if required, enforce global hash footer algorithm for init_boot
ifdef BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE
BOARD_AVB_INIT_BOOT_ADD_HASH_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
endif

# if required, enforce global hash footer algorithm for vendor_kernel
ifdef BOARD_VENDOR_KERNEL_BOOTIMAGE_PARTITION_SIZE
BOARD_AVB_VENDOR_KERNEL_BOOT_ADD_HASH_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
endif

# if required, enforce global hash footer algorithm for pvmfw
ifdef BOARD_PVMFWIMAGE_PARTITION_SIZE
BOARD_AVB_PVMFW_ADD_HASH_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
endif

# FP3 breaks when adding hashtree footers (at least on boot + dtbo) so filter it out when detected
# likely it could be enabled on the other partitions but this wasn't tested
ifeq ($(filter FP3,$(TARGET_DEVICE)),) # <-- likely we need to identify the root cause for this, i.e. e.g. "if chaining"?

# enforce global hashtree algorithm for boot, dtbo, recovery, system, system_other|ext|dlkm, product
BOARD_AVB_BOOT_ADD_HASH_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
BOARD_AVB_DTBO_ADD_HASH_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)

# enforce global hashtree algorithm for recovery but only when there is a dedicated recovery
ifneq ($(TARGET_NO_RECOVERY),true)
BOARD_AVB_RECOVERY_ADD_HASH_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
endif

BOARD_AVB_SYSTEM_OTHER_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
BOARD_AVB_SYSTEM_EXT_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
BOARD_AVB_SYSTEM_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
BOARD_AVB_PRODUCT_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)

# enforce global hashtree algorithm for vendor, odm
BOARD_AVB_ODM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
BOARD_AVB_VENDOR_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)

# enforce global hashtree algorithm for vendor_dlkm , odm_dlkm
BOARD_AVB_ODM_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
BOARD_AVB_VENDOR_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)

endif # ifeq filter FP3
