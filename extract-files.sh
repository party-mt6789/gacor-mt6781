#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=mt6781
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

function blob_fixup {
    case "$1" in
        system_ext/lib64/libsource.so)
            "${PATCHELF}" --add-needed "libui_shim.so" "${2}"
            ;;
        system_ext/lib64/libsink.so)
            "${PATCHELF}" --add-needed "libshim_sink.so" "$2"
            ;;
        vendor/lib64/libwifi-hal-mtk.so)
            "$PATCHELF" --set-soname libwifi-hal-mtk.so "${2}"
            ;;
        vendor/lib64/hw/consumerir.mt6781.so)
            "$PATCHELF" --set-soname consumerir.mt6781.so "${2}"
            ;;
        vendor/bin/mnld|\
        vendor/lib*/hw/android.hardware.sensors@2.X-subhal-mediatek.so|\
        vendor/lib*/librgbwlightsensor.so|\
        vendor/lib*/libaalservice.so)
            "$PATCHELF" --add-needed "libshim_sensors.so" "$2"
            ;;
        vendor/lib/hw/audio.primary.mt6781.so)
            "$PATCHELF" --add-needed "libstagefright_foundation-v33.so" "$2"
            ;;
        vendor/lib*/hw/vendor.mediatek.hardware.pq@2.15-impl.so)
            "$PATCHELF" --replace-needed "libutils.so" "libutils-v32.so" "$2"
            ;;
        vendor/lib64/hw/fingerprint.fpc.default.so)
            xxd -p "${2}" | sed "s/1f2afd7bc2a8c0035fd600000000ff8301d1fd7b02a9fd830091f85f03a9/1f2afd7bc2a8c0035fd600000000c0035fd6fd7b02a9fd830091f85f03a9/g" | xxd -r -p > "${2}".patched
            mv "${2}".patched "${2}"
            ;;
        vendor/bin/hw/android.hardware.media.c2@1.2-mediatek)
            "${PATCHELF}" --add-needed "libstagefright_foundation-v33.so" "${2}"
            "${PATCHELF}" --replace-needed "libavservices_minijail_vendor.so" "libavservices_minijail.so" "${2}"
            ;;
        vendor/lib64/hw/android.hardware.thermal@2.0-impl.so)
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
            ;;
        vendor/bin/hw/vendor.mediatek.hardware.mtkpower@1.0-service)
            "$PATCHELF" --replace-needed "android.hardware.power-V2-ndk_platform.so" "android.hardware.power-V2-ndk.so" "$2"
            ;;
        vendor/etc/init/vendor.mediatek.hardware.mtkpower@1.0-service.rc)
            echo "$(cat ${2}) input" > "${2}"
            ;;
	vendor/etc/init/init.batterysecret.rc)
            sed -i '/seclabel/d' "$2"
	    ;;
	vendor/etc/init/init.mi_thermald.rc)
            sed -i '/seclabel/d' "$2"
	    ;;
	vendor/etc/init/android.hardware.neuralnetworks@1.3-service-mtk-neuron.rc)
            sed -i 's/"sea"/"fleur"/' "$2"
            ;;
        vendor/bin/hw/vendor.dolby.hardware.dms@2.0-service)
            "$PATCHELF" --add-needed "libstagefright_foundation-v33.so" "$2"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
