#!/bin/sh

total_memory=$(grep MemTotal /proc/meminfo | awk '{print $2}')
scout_enabled=$(getprop persist.sys.stability.scout.enable)

# For all devices, enable scout by default
if [ -z $scout_enabled ]; then
    setprop persist.sys.stability.scout.enable true
fi

# For device with less than 6GB RAM, scout will work in lite mode. In LT mode
# scout will neither collet backtrace nor do any action that may cause exessive load.
scout_lightweight=$(getprop persist.sys.stability.litescout.enable)
if [ $total_memory -le 6291456 ]; then
    library_test=$(getprop persist.mtbf.test)
    omni_test=$(getprop persist.omni.test)
    sentinel_enabled=$(getprop persist.sys.stability.enable_sentinel_resource_monitor)
    # Sentinel is enabled on all devices by default in the prodcut config file
    # but on the user side, we didn't see any actual benefits on low-end devices
    # so disable it unless in MTBF/UAT to save cpu/memory/battery consumption
    if [ "$sentinel_enabled" = "true" ] && [ -z "$library_test" ]; then
        # If someone need to re-enable this feature by cloud config
        # they could set the value to 1 instead of true
        setprop persist.sys.stability.enable_sentinel_resource_monitor false
    fi
    if [ $total_memory -le 4194304 ] || [ "$library_test" != "true" ] && [ "$omni_test" != "1" ]; then
        if [ -z $scout_lightweight ]; then
            setprop persist.sys.stability.litescout.enable true
        fi
    else
        # While in MTBF/UAT, Scout will work in normal mode for 6GB RAM devices
        setprop persist.sys.stability.litescout.enable false
    fi
    # Set input anr timeout to 10s for devices with <=6G RAM
    input_anr_timeout=$(getprop persist.sys.stability.input_anr_timeout)
    if [ -z $input_anr_timeout ]; then
        setprop persist.sys.stability.input_anr_timeout 10000
    fi
fi

# For all device, scout will detect UI frozen and report it.
scout_detect_frozen=$(getprop persist.sys.stability.scout.check_frozen)
if [ -z $scout_detect_frozen ]; then
    setprop persist.sys.stability.scout.check_frozen true
fi

