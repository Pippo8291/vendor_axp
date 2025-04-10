#!/bin/bash
#############################################################################
# Parse a log for specific subjects to find matching CVE patches
# This script is part of AXP.OS https://axpos.org
#
# Copyright 2024-2025: steadfasterX <steadfasterX |AT| binbash #DOT# rocks>
# License: GPLv2
#############################################################################

KERNPATH="$1"
LOGFILE="$2"

usage() {
  echo "Usage: $0 [--search|-s SEARCH_STRING] [--parse|-p -k KERNEL_PATH -L LOGFILE_PATH]"
  echo ""
  echo "Options:"
  echo "  --search, -s SEARCH_STRING    Start the f_search function with the provided search string."
  echo "  --parse, -p                   Start the f_parse function with the required sub-arguments:"
  echo "                                -k KERNEL_PATH: Path to the kernel."
  echo "                                -L LOGFILE_PATH: Path to the logfile."
  echo ""
  echo "One of --search or --parse is required."
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --search|-s)
      if [ -n "$2" ]; then
        SEARCHSTR=$2
        shift 2
      else
        echo "Error: --search requires a search string."
        usage
      fi
      ;;
    --parse|-p)
      PARSE=true
      shift
      while [[ $# -gt 0 ]]; do
        case $1 in
          -k)
            if [ -n "$2" ]; then
              KERNPATH=$2
              shift 2
            else
              echo "Error: -k requires a kernel path."
              usage
            fi
            ;;
          -L)
            if [ -n "$2" ]; then
              LOGFILE=$2
              shift 2
            else
              echo "Error: -L requires a logfile path."
              usage
            fi
            ;;
          *)
            break
            ;;
        esac
      done
      ;;
    *)
      echo "Error: Unknown argument: $1"
      usage
      ;;
  esac
done

# parse a AXP.OS log (must be a clean build, i.e. startPatcher must have been run on a resetted workspace)
f_parse(){
    if [ -z "$KERNPATH" -o ! -d "$KERNPATH" -o -z "$LOGFILE" -o ! -f "$LOGFILE" ];then
        echo "Missing or wrong Kernel path and/or logfile name! usage: $0 <kernel-path> <full-path-to-logfile>"
        exit 4
    fi

    cd $KERNPATH

    for blame in $(grep error: "$LOGFILE" | grep -E ':[0-9]+:[0-9]+:'| cut -d / -f19-200 | cut -d : -f1-2 | grep : | sort -u | grep -vE '^$' | tr '\n' " " | sed 's#private/gs-google/##g');do
        echo "bp=${blame/:*} ln=${blame/*:}"
        export bp="${blame/:*}" ln="${blame/*:}"
        export commit=$(git blame $bp |grep " ${ln})" | cut -d " " -f1)
        echo "commit: >$commit<"
        export subject=$(git log --format=fuller -1 "$commit" | head -n7 | tail -n1 | sed -E 's/^\s+//g')
        echo "searching applied CVE for.. >${subject}<"
        if [ ! -z "$subject" ];then
            FCVE=$(grep "${subject}" "$LOGFILE" -B1 | grep "^processing:" | cut -d '/' -f2-20 | tr -d ' ')
            if [ -z "$TCVE" ];then
                TCVE="$FCVE"
            else
                dup=$(echo "$FCVE" | grep -c "$TCVE" || true)
                if [ $dup -eq 0 ];then
                    TCVE="${TCVE} $FCVE"
                fi
            fi
        else
            echo "ERROR: no subject found"; exit 2
        fi
        if [ $? -ne 0 ];then
            echo "Cannot find subject in LOG! not a CVE? NOTE: a CLEAN build incl. full patching is REQUIRED to find matching CVE's."
            exit 3
        fi
    done

    echo "parsing all troublemaker CVEs finished, now it's your turn to fix them!"

    if [ -z "$TCVE" ];then
        echo "Woot?! no CVE(s) found? NOTE: a CLEAN build incl. full patching is REQUIRED to find matching CVE's."
    else
        echo -en "\nRPOBLEMATIC_CVES: "
        for cv in $TCVE;do echo -n "\"$cv\" " ;done
        echo -e "\n\n"
    fi

}

# search based on a string, requires to source Scripts/init.sh before
f_search(){
    local WHAT="$1"
    WHERE="$DOS_SCRIPTS"

    which ugrep > /dev/null 2>&1|| (echo "ERROR: pls install 'ugrep' first"; exit 4)

    if [ ! -d "$DOS_PATCHES_LINUX_CVES" -o ! -d "$WHERE" ];then
      echo "ERROR: do you have sourced init.sh??"
      echo "ensure you do this from your android source directory:"
      echo "source build/envsetup.sh; source ../../Scripts/init.sh"
      exit 4
    fi

    for p in $(ugrep -l -r "$WHAT" $DOS_PATCHES_LINUX_CVES | sed "s#$DOS_PATCHES_LINUX_CVES##g");do
        #echo "DEBUG: found declaration of >$WHAT< in patch file: $p"
        for match in $(ugrep -r "$p" $WHERE | grep -v ':#' | cut -d ':' -f1);do
            echo "FOUND ${DOS_PATCHES_LINUX_CVES}${p} in $match"
        done
    done
}

if [ -n "$SEARCHSTR" ]; then
  f_search "$SEARCHSTR"
elif [ "$PARSE" == "true" ]; then
  if [ -z "$KERNPATH" ] || [ -z "$LOGFILE" ]; then
    echo "Error: --parse requires -k and -L arguments."
    usage
  fi
  f_parse "$KERNPATH" "$LOGFILE"
else
  usage
fi
