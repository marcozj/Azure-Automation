#!/bin/bash

#  This script is used by systemd /usr/lib/systemd/system/centrifycc-enroll.service

function prepare_for_cenroll()
{
    r=1
    NETWORK_ADDR_TYPE=${NETWORK_ADDR_TYPE:-PublicIP}
    case "$NETWORK_ADDR_TYPE" in
    PublicIP)
        CENTRIFYCC_NETWORK_ADDR=`curl --fail -s -H Metadata:True "http://169.254.169.254/metadata/instance?api-version=2020-06-01" | jq '.network' | jq '.interface[0]' | jq '.ipv4' | jq '.ipAddress[0]' | jq '.publicIpAddress'` | sed -e 's/^"//' -e 's/"$//'`
        r=$?
        ;; 
    PrivateIP)
        CENTRIFYCC_NETWORK_ADDR=`curl --fail -s -H Metadata:True "http://169.254.169.254/metadata/instance?api-version=2020-06-01" | jq '.network' | jq '.interface[0]' | jq '.ipv4' | jq '.ipAddress[0]' | jq '.privateIpAddress'` | sed -e 's/^"//' -e 's/"$//'`
        r=$?
        ;;
    HostName)
        CENTRIFYCC_NETWORK_ADDR=`hostname --fqdn`
		if [ "$CENTRIFYCC_NETWORK_ADDR" = "" ] ; then
			CENTRIFYCC_NETWORK_ADDR=`hostname`
		fi
        r=$?
        ;;
    esac
    if [ $r -ne 0 ];then
        return $r
    fi
    return $r
}

function generate_computer_name()
{
    case "$COMPUTER_NAME_FORMAT" in
    HOSTNAME)
        #host_name=`hostname`
        existing_hostname=`hostname`
        host_name="`echo $existing_hostname | cut -d. -f1`"
        if [ "$COMPUTER_NAME_PREFIX" = "" ];then
            COMPUTER_NAME="$host_name"
        else
            COMPUTER_NAME="$COMPUTER_NAME_PREFIX-$host_name"
        fi
        ;;
    INSTANCE_ID)
        instance_id=`curl --fail -s -H Metadata:True "http://169.254.169.254/metadata/instance?api-version=2020-06-01" | jq '.compute' | jq '.vmId'` | sed -e 's/^"//' -e 's/"$//'`
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: cannot get instance id" && return $r
        fi
        if [ "$COMPUTER_NAME_PREFIX" = "" ];then
            COMPUTER_NAME="$instance_id"
        else
            COMPUTER_NAME="$COMPUTER_NAME_PREFIX-$instance_id"
        fi
        ;;
    *)
        echo "$CENTRIFY_MSG_PREX: invalid computer name format: $COMPUTER_NAME_FORMAT" && return 1
        ;;
    esac
    return 0
}

prepare_for_cenroll
r=$?
if [ $r -ne 0 ];then
  exit $r
fi

generate_computer_name
r=$?
if [ $r -ne 0 ];then
  exit $r
fi

#CMDPARAMARRAY=($CMDPARAM)
# Need special handling. Simply reading CMDPARAM doesn't work for element with whitespace
IFS="|" read -a CMDPARAMARRAY <<< "$CMDPARAM"

CPARAMS=()
for i in $(echo ${!CMDPARAMARRAY[@]}); do
    VAR=${CMDPARAMARRAY[$i]}
    CPARAMS=("${CPARAMS[@]}" "$VAR")
done

/usr/sbin/cenroll  \
    --tenant "$TENANT_URL" \
    --code "$ENROLLMENT_CODE" \
    --features "$FEATURES" \
    --name "$COMPUTER_NAME" \
    --address "$CENTRIFYCC_NETWORK_ADDR" \
    "${CPARAMS[@]}"
    #"${CMDPARAMARRAY[@]}"