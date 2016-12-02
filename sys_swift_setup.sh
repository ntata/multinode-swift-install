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


################################################
# scripts to setup environment and install Swift
################################################


#*************General Information*************
# 1) /var/log/swift - /etc/rsyslog.d/10-swift.conf is the log file that enables rsyslog to write logs to /var/log/swift
# 2) /var/cache/swift - swift-recon dumps stats in the cache directory dedicated to each storage node
# 3) /var/run/swift - swift processes's pids are stored in /var/run/swift. 
# 4) /tmp/log/swift - a temporary directory used by some unit tests to run the profiler
# 5) memcached service stores user credentials along with the tokens. It is important to ensure its running before starting the swift services
# 6) This SAIO mimics the web solution  - with 4 physical devices mounted under /mnt/
#***************************************


# Ensures the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

SWIFT_USER="swift"
SWIFT_GROUP="swift"

SWIFT_PARTITION_START_BLOCK="2048"
SWIFT_PARTITION_END_BLOCK="3907029167"


SWIFT_DISK_BASE_DIR="/srv"
SWIFT_MOUNT_BASE_DIR="/mnt"

SWIFT_CONFIG_DIR="/etc/swift"
SWIFT_RUN_DIR="/var/run/swift"
SWIFT_CACHE_BASE_DIR="/var/cache"
SWIFT_PROFILE_LOG_DIR="/tmp/log/swift/profile"
SWIFT_LOG_DIR="/var/log/swift"

mkdir -p "${SWIFT_CONFIG_DIR}"
mkdir -p "${SWIFT_RUN_DIR}"
mkdir -p "${SWIFT_PROFILE_LOG_DIR}"
mkdir -p "${SWIFT_LOG_DIR}"

#Create partitions on devices attached

chown -R ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_RUN_DIR}
chown -R ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_PROFILE_LOG_DIR}
chown -R syslog.adm ${SWIFT_LOG_DIR}
chmod -R g+w ${SWIFT_LOG_DIR}

SWIFT_DISK="${SWIFT_DISK_BASE_DIR}/swift-disk"
for x in {1..8}; do
   SWIFT_DISK="${SWIFT_DISK_BASE_DIR}/swift-disk${x}"
   truncate -s "${SWIFT_DISK_SIZE_GB}GB" "${SWIFT_DISK}"
   mkfs.xfs -f "${SWIFT_DISK}"
done

# good idea to have backup of fstab before we modify it
cp /etc/fstab /etc/fstab.insert.bak

#TODO check whether swift-disk entry already exists
cat >> /etc/fstab << EOF
/srv/swift-disk1 /srv/1/node/sdb1 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0
/srv/swift-disk2 /srv/2/node/sdb2 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0
/srv/swift-disk3 /srv/3/node/sdb3 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0
/srv/swift-disk4 /srv/4/node/sdb4 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0
/srv/swift-disk5 /srv/1/node/sdb5 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0
/srv/swift-disk6 /srv/2/node/sdb6 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0
/srv/swift-disk7 /srv/3/node/sdb7 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0
/srv/swift-disk8 /srv/4/node/sdb8 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0
EOF

for x in {1..4}; do
   SWIFT_DISK_DIR="${SWIFT_DISK_BASE_DIR}/${x}"
   SWIFT_MOUNT_DIR="${SWIFT_MOUNT_BASE_DIR}/${x}"
   SWIFT_CACHE_DIR="${SWIFT_CACHE_BASE_DIR}/swift${x}"
   mkdir -p ${SWIFT_MOUNT_DIR}
   chown ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_MOUNT_DIR}

   # necessary? used anywhere?
   mkdir -p "${SWIFT_CACHE_DIR}"

   ln -s ${SWIFT_MOUNT_DIR} ${SWIFT_DISK_DIR}
done
mv ${SWIFT_CACHE_BASE_DIR}/swift1 ${SWIFT_CACHE_BASE_DIR}/swift

mkdir -p ${SWIFT_DISK_BASE_DIR}/1/node/sdb1
mkdir -p ${SWIFT_DISK_BASE_DIR}/2/node/sdb2
mkdir -p ${SWIFT_DISK_BASE_DIR}/3/node/sdb3
mkdir -p ${SWIFT_DISK_BASE_DIR}/4/node/sdb4

mkdir -p ${SWIFT_DISK_BASE_DIR}/1/node/sdb5
mkdir -p ${SWIFT_DISK_BASE_DIR}/2/node/sdb6
mkdir -p ${SWIFT_DISK_BASE_DIR}/3/node/sdb7
mkdir -p ${SWIFT_DISK_BASE_DIR}/4/node/sdb8

chown -R ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_DISK_BASE_DIR}

mount -a

chown -R ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_MOUNT_BASE_DIR}

# used by swift recon to dump the stats to cache
chown -R ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_CACHE_BASE_DIR}/swift*

SWIFT_USER_HOME="/home/${SWIFT_USER}"
SWIFT_USER_BIN="${SWIFT_USER_HOME}/bin"
mkdir -p ${SWIFT_USER_BIN}

SWIFT_LOGIN_CONFIG="${SWIFT_USER_HOME}/.bashrc"

cd ${SWIFT_USER_HOME}

EXPORT_TEST_CFG_FILE="export SWIFT_TEST_CONFIG_FILE=${SWIFT_CONFIG_DIR}/test.conf"
grep "${EXPORT_TEST_CFG_FILE}" ${SWIFT_LOGIN_CONFIG}
if [ "$?" -ne "0" ]; then
   echo "${EXPORT_TEST_CFG_FILE}" >> ${SWIFT_LOGIN_CONFIG}
fi

SWIFT_REPO_DIR="${SWIFT_USER_HOME}/swift"
SWIFT_CLI_REPO_DIR="${SWIFT_USER_HOME}/python-swiftclient"

if [ -d ${SWIFT_USER_HOME}/swift ]; then
   su - ${SWIFT_USER} -c 'cd swift && git pull'
else
   su - ${SWIFT_USER} -c 'git clone https://github.com/openstack/swift'
fi

if [ -d ${SWIFT_USER_HOME}/python-swiftclient ]; then
   su - ${SWIFT_USER} -c 'cd python-swiftclient && git pull'
else
   su - ${SWIFT_USER} -c 'git clone https://github.com/openstack/python-swiftclient'
fi

EXPORT_PATH="export PATH=${PATH}:${SWIFT_USER_BIN}"
grep "${EXPORT_PATH}" ${SWIFT_LOGIN_CONFIG}
if [ "$?" -ne "0" ]; then
   echo "${EXPORT_PATH}" >> ${SWIFT_LOGIN_CONFIG}
fi


echo "export PYTHONPATH=${SWIFT_USER_HOME}/swift" >> ${SWIFT_LOGIN_CONFIG}

cp ${SWIFT_REPO_DIR}/test/sample.conf ${SWIFT_CONFIG_DIR}/test.conf

cd ${SWIFT_REPO_DIR}/doc/saio/swift; cp -r * ${SWIFT_CONFIG_DIR}; cd -
chown -R ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_CONFIG_DIR}
find ${SWIFT_CONFIG_DIR}/ -name \*.conf | xargs sed -i "s/<your-user-name>/${SWIFT_USER}/"

cp ${SWIFT_REPO_DIR}/doc/saio/rsyslog.d/10-swift.conf /etc/rsyslog.d/
sed -i '2 s/^#//' /etc/rsyslog.d/10-swift.conf
sed -i 's/PrivDropToGroup syslog/PrivDropToGroup adm/g' /etc/rsyslog.conf
service rsyslog restart

cd ${SWIFT_REPO_DIR}/doc/saio/bin; cp * ${SWIFT_USER_BIN};
chown -R ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_USER_BIN}; cd -

sed -i "/find \/var\/log\/swift/d" ${SWIFT_USER_BIN}/resetswift
sed -i 's/\/dev\/sdb1/\/srv\/swift-disk/g' ${SWIFT_USER_BIN}/resetswift

#chnaging swift ports to 5*** series
find ${SWIFT_CONFIG_DIR} -type f -exec sed -i 's/^bind_port = \(6\)\([0-9]*\)/echo "bind_port = 5\2"/ge' {} \;
sed -i 's/^\(swift-ring-builder .*\)\([0-9]:\)\(6\)\([0-9][0-9][0-9]\)\(.*\)/echo "\1\25\4\5"/ge' ${SWIFT_USER_BIN}/remakerings

#install SAIO in development mode
#Use python setup.py install in order to install the application
cd ${SWIFT_CLI_REPO_DIR}
yes | pip install -r requirements.txt
yes | pip install -r test-requirements.txt
python setup.py develop
chown -R ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_CLI_REPO_DIR}

cd ${SWIFT_REPO_DIR}
yes | pip install -r requirements.txt
yes | pip install -r test-requirements.txt
python setup.py develop
chown -R ${SWIFT_USER}:${SWIFT_GROUP} ${SWIFT_REPO_DIR}
