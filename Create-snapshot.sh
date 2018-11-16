#!/usr/bin/env bash
set -x

# debug mode
debug=${1:-false}
download=${2:-false}

# today' date
snapshot_date=$(date +%y%m%d)

snapshot_local_path="~/sysop/glance-image"
mkdir -p ${snapshot_local_path}

for server_uuid in $(openstack server list --status shutoff --all-projects -f value -c ID); do
  # server's variables
  server_name=$(openstack server show ${server_uuid} -f value -c name)
  server_name_tolower=$(echo ${server_name} | awk '{ print tolower($0) }')
  snapshot_name="snapshot-${server_name_tolower}-${snapshot_date}"
  snapshot_file="${snapshot_name}.qcow2"
  snapshot_path="${snapshot_local_path}/${snapshot_file}"

  # checking for duplicate snapshot
  [ ! -z "$(openstack image show ${snapshot_name} -f value -c id 2>/dev/null)" ] && continue

  # create a snapshot from instance
  openstack server image create ${server_uuid} --name ${snapshot_name} --wait -f value -c UUID

  # download a snapshot to local disk
  if [ "$download" == "ture" ]; then
    snapshot_uuid=$(openstack image show ${snapshot_name} -f value -c id)
    openstack image save ${snapshot_uuid} --file ${snapshot_file}
  fi

  # if debug are true, delete test data
  if [ "$debug" == "true" ]; then
    openstack image delete ${snapshot_uuid}
    rm -f ${snapshot_file}
  fi
done