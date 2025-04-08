#####################################################################################
#
# This file is part of AXP.OS (https://axpos.org)
# LICENSE: GPLv3 (https://www.gnu.org/licenses/gpl-3.0.txt)
#
# Copyright (C) 2023-2025 steadfasterX <steadfasterX -AT- gmail #DOT# com>
#
#####################################################################################
# AXP.OS advanced AVB handling
#
# verification:
# $> external/avb/avbtool info_image --image vbmeta.img
# $> external/avb/avbtool verify_image --follow_chain_partitions --image vbmeta.img
#####################################################################################

# Enable android verified boot
BOARD_AVB_ENABLE := true

# AVB key size and hash
BOARD_AVB_ALGORITHM := SHA512_RSA4096

# pub key (avb_pkmd.bin) must be flashed to avb_custom_key partition
# see https://axpos.org/Bootloader-Lock
BOARD_AVB_KEY_PATH := user-keys/avb.pem

# BOARD_AVB_RECOVERY_KEY_PATH must be defined for if non-A/B is supported.
# See https://android.googlesource.com/platform/external/avb/+/master/README.md#booting-into-recovery
ifeq ($(TARGET_OTA_ALLOW_NON_AB),true)
ifneq ($(INSTALLED_RECOVERYIMAGE_TARGET),)
BOARD_AVB_RECOVERY_KEY_PATH := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1
endif
endif

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

# Using sha512 for the hashtree of all partitions
TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM := sha512

# overwrite general hashtree algorithms
TARGET_AVB_SYSTEM_HASHTREE_ALGORITHM := $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
TARGET_AVB_SYSTEM_OTHER_HASHTREE_ALGORITHM := $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
TARGET_AVB_SYSTEM_EXT_HASHTREE_ALGORITHM := $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
TARGET_AVB_SYSTEM_DLKM_HASHTREE_ALGORITHM := $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)

# enforce global hashtree footer algorithm for system
BOARD_AVB_SYSTEM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)

# FP3 breaks when adding hashtree footers (at least on boot + dtbo) so filter it out when detected
# likely it could be enabled on all other partitions but this wasn't tested
#ifeq ($(filter FP3,$(BDEVICE)),) # <-- cant get this working
ifneq ($(BDEVICE),FP3)   # <-- likely we need to identify the root cause for this, i.e. e.g. "if chaining"?

# enforce global hashtree algorithm for boot, dtbo, system, system_other|ext|dlkm, product
BOARD_AVB_BOOT_ADD_HASH_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)
BOARD_AVB_DTBO_ADD_HASH_FOOTER_ARGS += --hash_algorithm $(TARGET_AVB_GLOBAL_HASHTREE_ALGORITHM)

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

else

# overwrite testkeys on system partition if defined (e.g. FP3)
BOARD_AVB_SYSTEM_KEY_PATH := $(BOARD_AVB_KEY_PATH)

endif # ifeq FP3
