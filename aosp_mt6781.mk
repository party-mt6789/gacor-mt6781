#
# Copyright (C) 2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from common makefile
$(call inherit-product, device/xiaomi/mt6781-common/device.mk)

# Inherit some common PixelOS stuff.
$(call inherit-product, vendor/aosp/config/common_full_phone.mk)
