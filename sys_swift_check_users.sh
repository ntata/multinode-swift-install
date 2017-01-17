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


###########################################################
# Script to check if "swift" exists; if not, will be created
############################################################

# Ensures the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "" = "${SWIFT_USER}" ]; then
   export SWIFT_USER="ubuntu"
fi

if [ "" = "${SWIFT_GROUP}" ]; then
   export SWIFT_GROUP="ubuntu"
fi

#verify that swift group exists
if grep -q ${SWIFT_GROUP} /etc/group; then
    echo "swift user group exists"
else
   groupadd ${SWIFT_GROUP}
   echo "swift user group has been created"
fi

#verify swift user exists
if grep -q ${SWIFT_USER} /etc/passwd; then
   echo "swift user 'ubuntu' exists"
else
  useradd -g ${SWIFT_GROUP} -m -s /bin/bash ${SWIFT_USER}
  echo "swift user 'ubuntu' has been created"
   
  #add user to sudo group
  adduser ${SWIFT_USER} sudo
  echo "swift user has been added to the  group"
  echo "try 'sudo su swift' to switch to swift user and it will not prompt for password"
fi
   
#set no password for swift. 
if grep -q ${SWIFT_GROUP} /etc/sudoers; then
  continue
else
  echo "%${SWIFT_GROUP} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi   
