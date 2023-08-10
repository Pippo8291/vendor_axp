#!/bin/bash
###############################################################################
#
# This code is part of AXP.OS - https://axp.binbash.rocks
# LICENSE: GPLv3
#
# Copyright (C) 2023 steadfasterX <steadfasterX -AT- gmail #DOT# com>
# 
###############################################################################

# get current Android version number
export AXP_TARGET_VERSION=$(build/soong/soong_ui.bash --dumpvar-mode PLATFORM_VERSION  2>/dev/null)

# allow a custom OTA server URI, use default if unspecified
if [ -z "$CUSTOM_AXP_OTA_SERVER_URI" ];then
    export AXP_OTA_SERVER_URI="https://sfxota.binbash.rocks:8010/axp/a${AXP_TARGET_VERSION}/api/v1/{device}/{incr}"
else
    export AXP_OTA_SERVER_URI=$CUSTOM_AXP_OTA_SERVER_URI
fi
sed -i "s|%%AXP_OTA_SERVER_URI%%|${AXP_OTA_SERVER_URI}|g" vendor/axp/overlays/packages/apps/Updater/app/src/main/res/values/strings.xml

