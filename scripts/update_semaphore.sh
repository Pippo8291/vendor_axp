#!/bin/bash
#############################################################################
# Copyright 2024-2025: steadfasterX <steadfasterX |AT| binbash #DOT# rocks>
# License: GPLv2
#############################################################################
#
# script version 2.0.2

VER=$1

WHATOS=$(source /etc/os-release && echo $ID)

case $WHATOS in
    *buntu|[Dd]ebian) OSPKG=deb PKGINSTCMD="dpkg -i" ;;
    [Rr]ed[Hh]at|[Aa]lma*) OSPKG=rpm PKGINSTCMD="rpm -U";;
    *)echo "unknown OS ($WHATOS)" && exit 4;;
esac

[ -z "${OSPKG}" ] && echo "unknown OS" && exit 4
echo "supported OS detected: $WHATOS"

BURL="https://github.com/ansible-semaphore/semaphore/releases/download/v${VER}/semaphore_${VER}_linux_amd64.${OSPKG}"
XBIN=semaphore

[ -z "$VER" ] && echo "version missing (X.X.X) - no 'v' prefix!" && exit 4

if [ "$2" == "force" ];then
    case $OSPKG in
        rpm) PKGINSTCMD="$PKGINSTCMD --force";;
        deb) PKGINSTCMD="$PKGINSTCMD --force-downgrade";;
    esac
fi

echo "starting SQL backup"
/etc/cron.daily/semaphore-backup || exit $?
echo "finished SQL backup"

wget -qO /tmp/${XBIN}.${OSPKG} "$BURL" \
    && echo "downloaded ${XBIN} - version: $VER" \
    && echo "stopping ${XBIN} ........." \
    && systemctl stop ${XBIN}.service \
    && $PKGINSTCMD /tmp/${XBIN}.${OSPKG} \
    && rm /tmp/${XBIN}.${OSPKG} \
    && echo "starting ${XBIN} - $VER" \
    && systemctl start ${XBIN}.service \
    && systemctl status ${XBIN}.service && echo -e "\n\nUPDATING ${XBIN} TO VERSION: $VER WENT FINE!\n\n" && exit
    
systemctl status ${XBIN}.service

echo -e "\n\nERROR occured during updating ${XBIN} to version $VER\n"
exit 3
