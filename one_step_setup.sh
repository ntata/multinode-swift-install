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
#   This is a one step setup script
###############################################


# Ensures the script is being run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
   exit 1
fi

export SWIFT_USER="ubuntu"
export SWIFT_GROUP="ubuntu"
export SWIFT_USER_HOME="/home/${SWIFT_USER}"

./sys_swift_check_users.sh
./sys_swift_install_deps.sh
./sys_swift_setup.sh
./make_openrc.sh
cp start_swift.sh ${SWIFT_USER_HOME}
chown ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_USER_HOME}/start_swift.sh
cp stop_swift.sh ${SWIFT_USER_HOME}
chown ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_USER_HOME}/stop_swift.sh
su - ${SWIFT_USER} -c 'remakerings'
su - ${SWIFT_USER} -c 'swift-init start main'
