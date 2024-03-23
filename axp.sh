#!/bin/bash
###############################################################################
#
# This file is part of AXP.OS (https://axp.binbash.rocks)
# LICENSE: GPLv3 (https://www.gnu.org/licenses/gpl-3.0.txt)
#
# Copyright (C) 2023 steadfasterX <steadfasterX -AT- gmail #DOT# com>
# Copyright (C) 2024 steadfasterX <steadfasterX -AT- gmail #DOT# com>
#
###############################################################################

# be strict on failures
#set -e

CPWD=$PWD
# get build vars (require a lunch before!)
export AXP_TARGET_VERSION=$(build/soong/soong_ui.bash --dumpvar-mode PLATFORM_VERSION  2>/dev/null)
export AXP_TARGET_ARCH=$(build/soong/soong_ui.bash --dumpvar-mode TARGET_ARCH  2>/dev/null)
export AXP_KERNEL_PATH=$(build/soong/soong_ui.bash --dumpvar-mode TARGET_KERNEL_SOURCE  2>/dev/null)
export AXP_KERNEL_CONF=$(build/soong/soong_ui.bash --dumpvar-mode TARGET_KERNEL_CONFIG  2>/dev/null)

if [ "x$AXP_KERNEL_PATH" == x ];then
    echo "[AXP] ERROR: kernel path could not be detected"
else
    echo "[AXP] started ..."
fi

# allow a custom OTA server URI, use default if unspecified
if [ -z "$CUSTOM_AXP_OTA_SERVER_URI" ];then
    export AXP_OTA_SERVER_URI="https://sfxota.binbash.rocks:8010/axp/a${AXP_TARGET_VERSION}/api/v1/{device}/{incr}"
else
    export AXP_OTA_SERVER_URI=$CUSTOM_AXP_OTA_SERVER_URI
fi
cd vendor/axp/overlays/packages/apps/Updater/app/src/main/res/values/ && git checkout strings.xml
cd $CPWD
sed -i "s|%%AXP_OTA_SERVER_URI%%|${AXP_OTA_SERVER_URI}|g" vendor/axp/overlays/packages/apps/Updater/app/src/main/res/values/strings.xml && echo "[AXP] .. updated OTA url"

# patch kernel source to build wireguard module
if [ ! -f ".wg.patched" ];then
    cd $AXP_KERNEL_PATH
    if [ -d "net/wireguard" ];then rm -rf net/wireguard ;fi
    mkdir -p net/wireguard/compat
    if [ -f $CPWD/kernel/wireguard-linux-compat/kernel-tree-scripts/create-patch.sh ];then
        $CPWD/kernel/wireguard-linux-compat/kernel-tree-scripts/create-patch.sh | patch -p1 --no-backup-if-mismatch
        echo "[AXP] .. patched kernel sources for wireguard"
    else
        echo "[AXP] ERROR patching kernel sources for wireguard (missing compat patcher)!"
        exit 3
    fi
    cd $CPWD
    touch .wg.patched
else
    echo "[AXP] .. kernel is already patched for wireguard (patch indicator exists)"
fi

# patch kernel defconfig
if [ ! -f "$AXP_KERNEL_PATH/.defconf.patched" ];then
    for cf in $AXP_DEFCONFIG_GLOBALS; do
       grep -q "^$cf=y" $AXP_KERNEL_PATH/arch/$AXP_TARGET_ARCH/configs/$AXP_KERNEL_CONF || echo -e "\n$cf=y" >> $AXP_KERNEL_PATH/arch/$AXP_TARGET_ARCH/configs/$AXP_KERNEL_CONF
       echo "[AXP] .. kernel globals defconfig $cf has been set"
    done
    for cfd in $AXP_DEFCONFIG_DEVICE; do
       grep -q "^$cfd" $AXP_KERNEL_PATH/arch/$AXP_TARGET_ARCH/configs/$AXP_KERNEL_CONF || echo -e "\n$cfd" >> $AXP_KERNEL_PATH/arch/$AXP_TARGET_ARCH/configs/$AXP_KERNEL_CONF
       echo "[AXP] .. kernel device specific defconfig $cfd has been set"
    done
    touch $AXP_KERNEL_PATH/.defconf.patched
else
    echo "[AXP] .. kernel defconfig is already patched (patch indicator exists)"
fi

# handle OpenEUICC incl submodules (sync-s within the manifest does not work!)
echo "[AXP] .. initiating OpenEUICC submodules"
cd packages/apps/OpenEUICC
git submodule update --init && echo "[AXP] .. OpenEUICC submodules initiated successfully"
cd $CPWD
if [ "$AXP_BUILD_OPENEUICC" != "true" ];then
    echo "[AXP] .. skip building OpenEUICC (set AXP_BUILD_OPENEUICC=true in divested.vars.DEVICE to build)"
    sed -i -E 's/^PRODUCT_PACKAGES.*OpenEUICC/# openeuicc disabled by AXP.OS/g' vendor/divested/packages.mk
fi

echo "[AXP] ended with $? ..."
