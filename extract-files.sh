#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=sm8250-common
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        system/bin/init.qti.chg_policy.sh)
            sed -i 's|/vendor/bin/sh|/sbin/sh|g' "${2}"
            sed -i '/PATH=/d' "${2}"
            ;;
        vendor/etc/init/vendor.qti.hardware.charger_monitor@1.0-service.rc \
        | vendor/etc/init/vendor.qti.hardware.vibrator.service.xiaomi_kona.rc)
            sed -i '/class /d' "${2}"
            sed -i 's|/vendor/bin/hw|/system/bin|g' "${2}"
            sed -i 's|/vendor/bin|/system/bin|g' "${2}"
            ;;
        vendor/etc/init/init.batterysecret.rc)
            sed -i '/class /d' "${2}"
            sed -i 's|/vendor/bin|/system/bin|g' "${2}"
            sed -i 's|u:r:batterysecret:s0|u:r:recovery:s0|g' "${2}"
            sed -i 's|property:sys.boot_completed=1|boot|g' "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
