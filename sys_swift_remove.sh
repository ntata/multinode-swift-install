#!/bin/bash

#Author: Paul Dardeau <paul.dardeau@intel.com>
#        Nandini Tata <nandini.tata@intel.com>
# Copyright (c) 2016 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.


###############################################
# Script to destoy environment created for Swift
################################################

#Ensures script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

SWIFT_DISK_BASE_DIR="/srv"
SWIFT_MOUNT_BASE_DIR="/mnt"

SWIFT_CONFIG_DIR="/etc/swift"
SWIFT_RUN_DIR="/var/run/swift"
SWIFT_CACHE_BASE_DIR="/var/cache"
SWIFT_PROFILE_LOG_DIR="/tmp/log/swift"

# unmount loopbacks
umount /mnt/sdb1

# remove files and directories
rm -rf ${SWIFT_DISK_BASE_DIR}
rm -rf ${SWIFT_MOUNT_BASE_DIR}
rm -rf ${SWIFT_CONFIG_DIR}
rm -rf ${SWIFT_PROFILE_LOG_DIR}
rm -rf ${SWIFT_RUN_DIR}
for x in {1..4}; do
   rm -rf ${SWIFT_CACHE_BASE_DIR}/swift${x}
done

echo "don't forget to manually remove entries from /etc/fstab"
