#!/bin/bash
#############################################################################
# Copyright 2024-2025: steadfasterX <steadfasterX |AT| binbash #DOT# rocks>
# License: GPLv2
#############################################################################
#
# script version 2.0.3

VER=$1

WHATOS=$(source /etc/os-release && echo $ID)

[ $(id -u) != 0 ] && echo must be run with sudo && exit 4

case $WHATOS in
    *buntu|[Dd]ebian) OSPKG=deb PKGINSTCMD="dpkg -i" ;;
    [Rr]ed[Hh]at|[Aa]lma*) OSPKG=rpm PKGINSTCMD="rpm -U";;
    [Mm]anjaro|[Aa]rch) OSPKG=tar.gz PKGINSTCMD="" ;;
    *)echo "unknown OS ($WHATOS)" && exit 4;;
esac

[ -z "${OSPKG}" ] && echo "unknown OS" && exit 4
echo "supported OS detected: $WHATOS"

BURL="https://github.com/ansible-semaphore/semaphore/releases/download/v${VER}/semaphore_${VER}_linux_amd64.${OSPKG}"
XBIN=semaphore
SVCUSER=semaphore

[ -z "$VER" ] && echo "version missing (X.X.X) - no 'v' prefix!" && exit 4

if [ "$2" == "force" ];then
    case $OSPKG in
        rpm) PKGINSTCMD="$PKGINSTCMD --force";;
        deb) PKGINSTCMD="$PKGINSTCMD --force-downgrade";;
    esac
fi

if [ "$OSPKG" == "tar.gz" ];then
    cd /tmp
    tar xzf ${XBIN}.${OSPKG} semaphore
fi  

echo "starting SQL backup"
#/etc/cron.daily/semaphore-backup || exit $?
echo "finished SQL backup"

wget -qO /tmp/${XBIN}.${OSPKG} "$BURL" \
    && echo "downloaded ${XBIN} - version: $VER" \
    && echo "stopping ${XBIN} ........." \
    && systemctl stop ${XBIN}.service \
    && if [ "$OSPKG" == "tar.gz" ];then mv /tmp/$XBIN /opt/semaphore/ && chmod 750 /opt/semaphore/$XBIN && chown $SVCUSER /opt/semaphore/$XBIN; else $PKGINSTCMD /tmp/${XBIN}.${OSPKG};fi \
    && rm /tmp/${XBIN}.${OSPKG} \
    && echo "starting ${XBIN} - $VER" \
    && systemctl start ${XBIN}.service \
    && systemctl status ${XBIN}.service && echo -e "\n\nUPDATING ${XBIN} TO VERSION: $VER WENT FINE!\n\n" && exit
    
systemctl status ${XBIN}.service

echo -e "\n\nERROR occured during updating ${XBIN} to version $VER\n"
exit 3
