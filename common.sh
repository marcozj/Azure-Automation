#!/bin/bash

################################################################################
#
# Copyright 2017 Centrify Corporation
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Common script for AWS automation orchestration
#
#
# This sample script is to be used by centrifycc.sh and centrifydc.sh


function detect_os()
{
    basic_type=`uname -s`
    if [ "$basic_type" != "Linux" ];then
        echo "$CENTRIFY_MSG_PREX: cannot support the OS $basic_type"
        return 1
    fi

    if [ -f /etc/centos-release ];then
        if grep -w 'CentOS' /etc/centos-release >/dev/null ;then
            OS_NAME=centos
            OS_VERSION=`awk '{printf("%s",$4)}' /etc/centos-release`
            if [ "$OS_VERSION" = "" ];then
                echo "$CENTRIFY_MSG_PREX: detect OS version failed according to /etc/centos-release"
                return 1
            fi
        else
            echo "$CENTRIFY_MSG_PREX: detect OS type failed according to /etc/centos-release"
            return 1
        fi
    elif [ -f /etc/SuSE-release ];then
        if grep -w 'SUSE' /etc/SuSE-release >/dev/null;then
            OS_NAME='sles'
            OS_VERSION=`grep 'VERSION =' /etc/SuSE-release | cut -d ' ' -f 3`
            if [ "$OS_VERSION" = "" ];then
                echo "$CENTRIFY_MSG_PREX: detect OS version failed according to /etc/SuSE-release"
                return 1
            fi
        else
            echo "$CENTRIFY_MSG_PREX: detect OS type failed according to /etc/SuSE-release"
            return 1
        fi
    elif [ -f /etc/redhat-release ];then
        if grep -w 'Red Hat' /etc/redhat-release >/dev/null ;then
            OS_NAME=rhel
            OS_VERSION=`sed -n 's/^[^0-9]*\(\([0-9]\+\.*[0-9]*\)\+\)[^0-9]*$/\1/p' /etc/redhat-release`
            if [ "$OS_VERSION" = "" ];then
                echo "$CENTRIFY_MSG_PREX: detect OS version failed according to /etc/redhat-release"
                return 1
            fi
        else
            echo "$CENTRIFY_MSG_PREX: detect OS type failed according to /etc/redhat-release"
            return 1
        fi
    elif [ -f /etc/system-release ]; then
        if grep 'Amazon Linux' /etc/system-release >/dev/null ;then
            OS_NAME='amzn'
            OS_VERSION=`awk -F ':' '{i=NF-1;printf("%s:%s", $i,$NF)}' /etc/system-release-cpe`
            if [ "$OS_VERSION" = "" ];then
                echo "$CENTRIFY_MSG_PREX: detect OS version failed according to /etc/system-release"
                return 1
            fi
        else
            echo "$CENTRIFY_MSG_PREX: detect OS type failed according to /etc/system-release"
            return 1
        fi
    elif [ -f /etc/lsb-release ];then
        if grep 'Ubuntu' /etc/lsb-release >/dev/null ;then
            OS_NAME='ubuntu'
            OS_VERSION=`grep 'DISTRIB_RELEASE' /etc/lsb-release | cut -d '=' -f 2`
            if [ "$OS_VERSION" = "" ];then
                echo "$CENTRIFY_MSG_PREX: detect OS version failed according to /etc/lsb-release"
                return 1
            fi
        else
            echo "$CENTRIFY_MSG_PREX: detect OS type failed according to /etc/lsb-release"
            return 1
        fi
    else
        echo "$CENTRIFY_MSG_PREX: detect OS type failed and can currently be detected OS is: RedHat CentOS SuSE AmazonLinux"
        return 1
    fi
    OS_BIT=`getconf LONG_BIT`  
    if [ "$OS_BIT" = "" ];then
        echo "$CENTRIFY_MSG_PREX: detect OS 32/64 bit failed"
        return 1
    fi
    return 0
}

function check_supported_os()
{
    deploy_for="$1"
    support_ssm="$2"
    if [ "$support_ssm" != "support_ssm" -a "$support_ssm" != "not_support_ssm" ];then
        echo "$CENTRIFY_MSG_PREX: the second parameter of check_supported_os is invalid"
        return 1
    fi
    r=1
    if [ "$deploy_for" = "centrifydc" ];then
        case "$OS_NAME" in 
        rhel|centos)
            case "$OS_VERSION" in
            6|6.*|7|7.*|8|8.0|8.*)
                r=0
                ;;
            *)
                r=1
                echo "$CENTRIFY_MSG_PREX: doesn't support the OS $OS_NAME-$OS_VERSION currently"
                ;;
            esac
            ;;
        amzn)
            r=0
            ;;
        ubuntu)
            case "$OS_VERSION" in
            14|14.*|16|16.*|18|18.*)
                r=0
                ;;
            *)
                r=1
                echo "$CENTRIFY_MSG_PREX: doesn't support the OS $OS_NAME-$OS_VERSION currently"
                ;;
            esac
            ;;
        sles)
            if [ "$support_ssm" = "support_ssm" ];then
                echo "$CENTRIFY_MSG_PREX: AWS Run Command feature is not supported on SUSE"
                return 1
            fi
            if [ "$OS_BIT" = 32 ];then
                echo "$CENTRIFY_MSG_PREX: doesn't support SUSE for 32 bit"
                return 1
            fi
            case "$OS_VERSION" in
            11|11.*|12|12.*)
                r=0
                ;;
            *)
                r=1
                echo "$CENTRIFY_MSG_PREX: doesn't support the OS $OS_NAME-$OS_VERSION currently"
                ;;
            esac
            ;;
        *)
            r=1
            echo "$CENTRIFY_MSG_PREX: doesn't support the OS $OS_NAME-$OS_VERSION currently"
            ;;
        esac
    elif [ "$deploy_for" = "centrifycc" ];then
        if [ "$OS_BIT" = "32" ];then
            echo "$CENTRIFY_MSG_PREX: doesn't support the OS for 32 bit"
            return 1
        fi
        case "$OS_NAME" in 
        rhel|centos)
            case "$OS_VERSION" in
            6|6.*|7|7.*|8|8.0|8.*)
                r=0
                ;;
            *)
                r=1
                echo "$CENTRIFY_MSG_PREX: doesn't support the OS $OS_NAME-$OS_VERSION currently"
                ;;
            esac
            ;;
        amzn)
            r=0
            ;;
        ubuntu)
            case "$OS_VERSION" in
            14|14.*|16|16.*|18|18.*)
                r=0
                ;;
            *)
                r=1
                echo "$CENTRIFY_MSG_PREX: doesn't support the OS $OS_NAME-$OS_VERSION currently"
                ;;
            esac
            ;;
        sles)
            if [ "$support_ssm" = "support_ssm" ];then
                echo "$CENTRIFY_MSG_PREX: AWS Run Command feature is not supported on SUSE"
                return 1
            fi
            case "$OS_VERSION" in
            11|11.*|12|12.*)
                r=0
                ;;
            *)
                r=1
                echo "$CENTRIFY_MSG_PREX: doesn't support the OS $OS_NAME-$OS_VERSION currently"
                ;;
            esac
            ;;
        *)
            r=1
            echo "$CENTRIFY_MSG_PREX: doesn't support the OS $OS_NAME-$OS_VERSION currently"
            ;;
        esac
    else
        echo "$CENTRIFY_MSG_PREX: please specify centrifydc or centriycc to check if it is supported on this OS"
        r=1
    fi

    return $r
}

function common_prerequisite()
{
    r=1
    case "$OS_NAME" in
    rhel|amzn|centos)
        # Just directly install it whatever it has installed or not.
        # Even though it has been installed, the yum install will do nothing 
        # and return 0.
        yum install selinux-policy-targeted -y
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: selinux-policy-targeted installation failed"
            return $r
        fi
        yum install perl -y
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: perl installation failed"
            return $r
        fi
        yum install jq -y
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: jq installation failed"
            return $r
        fi
        ;;
    sles)
        sudo zypper -n install apparmor-profiles yast2-apparmor
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: apparmor installation failed"
            return $r
        fi
        ;;
    *)
        echo "$CENTRIFY_MSG_PREX: need not install perl and selinux-policy-targeted"
        r=0
        ;;
    esac
    [ $r -ne 0 ] && return $r

    if [ "$ENABLE_SSM_AGENT" = "yes" ];then
        install_aws_ssm_agent
        r=$?
    fi
    return $r
}

function download_install_rpm
{
    url_prefix="$1"
    rpm_package="$2"
    if [ "$url_prefix" = "" -o "$rpm_package" = "" ];then
        echo "$CENTRIFY_MSG_PREX: must specify url prefix and rpm packagename."
        return 1
    fi

    download_url="$url_prefix/$rpm_package"
    download_dir=/tmp
    # Change to GitHub link. It needs -L flag
    #curl --fail -s -o $download_dir/$rpm_package $download_url
    curl --fail -s -o $download_dir/$rpm_package -L $download_url
    r=$?
    if [ $r -ne 0 ];then
        echo "$CENTRIFY_MSG_PREX: download the rpm package $rpm_package unsuccessfully"
        return $r
    fi
        
    case "$OS_NAME" in
    rhel|amzn|centos|sles)
        rpm -ivh $download_dir/$rpm_package
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: install the rpm package $rpm_package unsuccessfully"
            return $r
        fi
        ;;
    ubuntu)
        dpkg -i $download_dir/$rpm_package
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: install the rpm package $rpm_package unsuccessfully"
            return $r
        fi
        ;;
    *)
        echo "$CENTRIFY_MSG_PREX: doesn't support installing the package $rpm_package on the OS $OS_NAME currently"
        r=1
        ;;
    esac
    rm -rf $download_dir/$rpm_package
    return $r
}

function prepare_repo()
{
    r=1
    case "$OS_NAME" in
    rhel|amzn|centos)
        cat >/etc/yum.repos.d/centrify.repo <<END
[centrify]
name=centrify
baseurl=https://$CENTRIFY_REPO_CREDENTIAL@repo.centrify.com/rpm-redhat/
enabled=1
repo_gpgcheck=1
gpgcheck=1
gpgkey=https://edge.centrify.com/products/RPM-GPG-KEY-centrify
END
        chmod 0600 /etc/yum.repos.d/centrify.repo
        yum clean all -y
        yum list CentrifyDC -y 
        r=$?
        ;;
    sles)
        cat >/etc/zypp/repos.d/centrify-rpm-suse.repo <<END
[centrify-rpm-suse]
name=centrify-rpm-suse
enabled=1
autorefresh=1
baseurl=https://$CENTRIFY_REPO_CREDENTIAL@repo.centrify.com/rpm-suse
type=rpm-md
repo_gpgcheck=1
gpgcheck=1
gpgkey=https://edge.centrify.com/products/RPM-GPG-KEY-centrify
END
        chmod 0600 /etc/zypp/repos.d/centrify-rpm-suse.repo
        zypper clean -a
        zypper --gpg-auto-import-keys refresh
        r=$?
        ;;
    ubuntu)
        bash -c 'wget -O - https://edge.centrify.com/products/RPM-GPG-KEY-centrify | apt-key add -'
        sed -i -r 's/^[[:blank:]]*no-debsig[[:blank:]]*$/#no-debsig/' /etc/dpkg/dpkg.cfg
        echo "deb https://$CENTRIFY_REPO_CREDENTIAL@repo.centrify.com/deb stable main" >> /etc/apt/sources.list
        apt-get -y clean
        apt-get -y update
        r=$?
        ;;
    *)
        echo "$CENTRIFY_MSG_PREX: Centrify doesn't support the OS $OS_NAME currently"
        r=1
    esac
    return $r
}

function install_packages_from_repo()
{
    packages=$*
    if [ "$packages" = "" ];then
        echo "$CENTRIFY_MSG_PREX: must specify which Centrify packages will be installed"
        return 1
    fi
    r=1
    case "$OS_NAME" in
    rhel|amzn|centos)
        # yum install will still succeed and do nothing even though the packages are already installed before.
        yum install $packages -y
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: yum install packages[$packages] failed!" 
            return $r
        fi
        ;;
    sles)
        # The two lines are necessary to import gpgkey, and don't try to delete them.
        zypper clean -a
        zypper --gpg-auto-import-keys refresh
        zypper --non-interactive install $packages
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: zypper install packages[$packages] failed!" 
            return $r
        fi
        ;;
    ubuntu)
        apt-get -y install $packages
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: apt-get install packages[$packages] failed!" 
            return $r
        fi
        ;;
    *)
        echo "$CENTRIFY_MSG_PREX doesn't support the OS $OS_NAME"
        r=1
        ;;
    esac
    return $r
}

function install_aws_ssm_agent_on_ubuntu()
{
    case "$OS_VERSION" in
        14|14*)
            aws_ssm=`dpkg -l  |  grep -E 'amazon-ssm-agent' | awk '{printf("%s", $2)}'`
            info=`status amazon-ssm-agent`
            is_old_os="true"
            ;;
        16|16*)
            #16.04 version with build date earlier than 2018-06-27 uses dpkg and later ones uses snap to install services
            
            ami_id=`curl 169.254.169.254/latest/meta-data/ami-id`
            #get build date
            ami_built_on=`aws ec2 describe-images --image-ids $ami_id --region $region --output text | awk '{print $13}'`
            if [ -z $ami_built_on ]; then
                echo "$CENTRIFY_MSG_PREX: could not retreive built date of the ami"
                return 1
            fi
            
            ami_built_on=`date -d "$ami_built_on" +%s`
            date_identifier=`date -d "2018-06-27" +%s`
            if [ $ami_built_on -lt $date_identifier ]; then
                aws_ssm=`dpkg -l  |  grep -E 'amazon-ssm-agent' | awk '{printf("%s", $2)}'`
                info=`systemctl status amazon-ssm-agent`
                is_old_os="true"
            else
                aws_ssm=`snap list | grep -E 'amazon-ssm-agent' | awk '{printf("%s", $1)}'`
                info=`systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service`
                is_old_os="false"
            fi
            ;;
        18|18*)
            aws_ssm=`snap list | grep -E 'amazon-ssm-agent' | awk '{printf("%s", $1)}'`
            info=`systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service`
            is_old_os="false"
            ;;

    esac
        
    if [ "$aws_ssm" = "" ];then
        aws_ssm_installed=no
    else
        aws_ssm_installed=yes
    fi
    if [ "$aws_ssm_installed" = "no" ];then
        if [ "$is_old_os" = "true" ];then
            if [ "$OS_BIT" = "64" ];then
                curl --fail --silent https://amazon-ssm-$region.s3.amazonaws.com/latest/debian_amd64/amazon-ssm-agent.deb -o /tmp/amazon-ssm-agent.deb
            else 
                curl --fail --silent https://amazon-ssm-$region.s3.amazonaws.com/latest/debian_386/amazon-ssm-agent.deb -o /tmp/amazon-ssm-agent.deb
            fi
            r=$?
            if [ $r -ne 0 ];then
                echo "$CENTRIFY_MSG_PREX: curl download amazon-ssm-agent rpm package failed"
                return $r
            fi
            
            dpkg -i /tmp/amazon-ssm-agent.deb
    
        else
            snap install amazon-ssm-agent --classic
        fi
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: amazon-ssm-agent installation failure occurred" 
            return $r
        fi
    fi
 
    try=5
    r=1

    while [ $try -gt 0 ];do
    if echo $info | grep 'running' >/dev/null;then
        r=0
        break
    else
        r=1
        sleep 2
    fi
    try=$((try-1))
    done


    if [ $r -eq 0 ];then
        if [ "$is_old_os" = "true" ];then
            rm -rf /tmp/amazon-ssm-agent.deb
        fi
    else
        echo "amazon-ssm-agent doesn't start successfully"
    fi

    return $r
}

function install_aws_ssm_agent_on_rhel()
{
    yum list installed | grep -E -w '^amazon-ssm-agent' >/dev/null
    r=$?
    if [ $r -ne 0 ];then
        if [ "$OS_BIT" = "64" ];then
            curl --fail --silent https://amazon-ssm-$region.s3.amazonaws.com/latest/linux_amd64/amazon-ssm-agent.rpm -o /tmp/amazon-ssm-agent.rpm 
        elif [ "$OS_BIT" = "32" ];then
            curl --fail --silent https://amazon-ssm-$region.s3.amazonaws.com/latest/linux_386/amazon-ssm-agent.rpm -o /tmp/amazon-ssm-agent.rpm 
        fi
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: curl download amazon-ssm-agent rpm package failed"
            return $r
        fi
        yum install -y /tmp/amazon-ssm-agent.rpm
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: amazon-ssm-agent installation failure occurred" 
            return $r
        fi
    fi

    case "$OS_NAME" in
    amzn)
	    if [ -f /usr/bin/systemctl ] ; then
			ctl_cmd_prefix='systemctl '
		else
			ctl_cmd_prefix=''
		fi
        ;;
    rhel|centos)
        case "$OS_VERSION" in
        6|6.*)
            ctl_cmd_prefix=''
            ;;
        7|7.*)
            ctl_cmd_prefix='systemctl '
            ;;
        esac
        ;;
    esac
                
    try=5
    r=1
    while [ $try -gt 0 ];do
        info=`${ctl_cmd_prefix}status amazon-ssm-agent`
        if echo $info | grep 'running' >/dev/null;then
            r=0
            break
        else
            r=1
            sleep 2
        fi
        try=$((try-1))
    done
    if [ $r -eq 0 ];then
        rm -rf /tmp/amazon-ssm-agent.rpm
    else
        echo "amazon-ssm-agent doesn't start successfully"
    fi
    return $r
}

function install_aws_ssm_agent()
{
    region=`curl --fail --silent http://169.254.169.254/latest/meta-data/placement/availability-zone`
    r=$?
    if [ $r -ne 0 ];then
        echo "$CENTRIFY_MSG_PREX: curl try to get available region failed"
        return $r
    fi
        
    if echo $region | grep -E '[0-9][a-z]$' >/dev/null ;then
      region=`echo $region | sed -n 's/[a-z]$//p'`
    fi
    rm -rf /tmp/amazon-ssm-agent.rpm >/dev/null 2>/dev/null
    rm -rf /tmp/amazon-ssm-agent.deb >/dev/null 2>/dev/null
    r=1
    case "$OS_NAME" in
    amzn|centos|rhel)
        install_aws_ssm_agent_on_rhel
        r=$?
        ;;
    ubuntu)
        install_aws_ssm_agent_on_ubuntu
        r=$?
        ;;
    *)
        echo "$CENTRIFY_MSG_PREX: the OS $OS_NAME is not supported"
        ;;
    esac
          
    if [ $r -ne 0 ];then
      echo "$CENTRIFY_MSG_PREX: AWS SSM Agent Installation failed"
      return $r 
    fi
    return 0
}

function enable_sshd_password_auth()
{
    ssh_from=''
    if test -x /usr/share/centrifydc/sbin/sshd ;then
        if grep -E '^PasswordAuthentication[[:space:]]+no[[:space:]]*$' /etc/centrifydc/ssh/sshd_config >/dev/null ; then
            ssh_from='centrifydc'
            src_conf=/etc/centrifydc/ssh/sshd_config
            backup_conf=/etc/centrifydc/ssh/sshd_config.deploy_backup
        fi
    else
        if grep -E '^PasswordAuthentication[[:space:]]+no[[:space:]]*$' /etc/ssh/sshd_config >/dev/null ; then
            ssh_from='stock'
            src_conf=/etc/ssh/sshd_config
            backup_conf=/etc/ssh/sshd_config.centrify_backup
        fi
    fi
    if [ "$ssh_from" != "" ];then
        [ ! -f $backup_conf ] && cp $src_conf $backup_conf
        /bin/sed -i -r 's/^PasswordAuthentication[[:space:]]+no[[:space:]]*$/#PasswordAuthentication no/g' $src_conf
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: Comment PasswordAuthentication in $src_conf failed!" 
            return $r
        fi
        r=1
        case "$OS_NAME" in
        ubuntu)
            if [ "$ssh_from" = "centrifydc" ];then
                service centrify-sshd restart 
            else
                service ssh restart
            fi
            r=$?
            ;;
        *)
            if [ "$ssh_from" = "centrifydc" ];then
                sshd_name=centrify-sshd
            else
                sshd_name=sshd
            fi
            if [ -x /usr/bin/systemctl ]; then
                systemctl restart $sshd_name.service
            else
                /etc/init.d/$sshd_name restart
            fi
            r=$?
            ;;
        esac
        return $r
    fi
   
    return 0
}

function enable_sshd_challenge_response_auth()
{
    ssh_from=''
    if test -x /usr/share/centrifydc/sbin/sshd ;then
        if grep -E '^ChallengeResponseAuthentication[[:space:]]+no[[:space:]]*$' /etc/centrifydc/ssh/sshd_config >/dev/null ; then
            ssh_from='centrifydc'
            src_conf=/etc/centrifydc/ssh/sshd_config
            backup_conf=/etc/centrifydc/ssh/sshd_config.deploy_backup
        fi
    else
        if grep -E '^ChallengeResponseAuthentication[[:space:]]+no[[:space:]]*$' /etc/ssh/sshd_config >/dev/null ; then
            ssh_from='stock'
            src_conf=/etc/ssh/sshd_config
            backup_conf=/etc/ssh/sshd_config.centrify_backup
        fi
    fi
    if [ "$ssh_from" != "" ];then
        [ ! -f $backup_conf ] && cp $src_conf $backup_conf
        /bin/sed -i -r 's/^ChallengeResponseAuthentication[[:space:]]+no[[:space:]]*$/ChallengeResponseAuthentication yes/g' $src_conf
        r=$?
        if [ $r -ne 0 ];then
            echo "$CENTRIFY_MSG_PREX: Update ChallengeResponseAuthentication in $src_conf failed!"
            return $r
        fi
        r=1
        case "$OS_NAME" in
        ubuntu)
            if [ "$ssh_from" = "centrifydc" ];then
                service centrify-sshd restart
            else
                service ssh restart
            fi
            r=$?
            ;;
        *)
            if [ "$ssh_from" = "centrifydc" ];then
                sshd_name=centrify-sshd
            else
                sshd_name=sshd
            fi
            if [ -x /usr/bin/systemctl ]; then
                systemctl restart $sshd_name.service
            else
                /etc/init.d/$sshd_name restart
            fi
            r=$?
            ;;
        esac
        return $r
    fi
   
    return 0
}

function enable_use_my_account()
{
    if [ "$CENTRIFYCC_USE_MY_ACCOUNT" = "yes" ];then
        curl --fail -s -o /etc/ssh/pas_ca.pub $CENTRIFYCC_TENANT_URL/servermanage/getmastersshkey
        ssh_from=''
        if test -x /usr/share/centrifydc/sbin/sshd ;then
            if ! grep -E '^TrustedUserCAKeys' /etc/centrifydc/ssh/sshd_config >/dev/null ; then
                ssh_from='centrifydc'
                src_conf=/etc/centrifydc/ssh/sshd_config
                backup_conf=/etc/centrifydc/ssh/sshd_config.deploy_backup
            fi
        else
            if ! grep -E '^TrustedUserCAKeys' /etc/ssh/sshd_config >/dev/null ; then
                ssh_from='stock'
                src_conf=/etc/ssh/sshd_config
                backup_conf=/etc/ssh/sshd_config.centrify_backup
            fi
        fi

        if [ "$ssh_from" != "" ];then
            [ ! -f $backup_conf ] && cp $src_conf $backup_conf
            /bin/sed -i '/^TrustedUserCAKeys/d' $src_conf
            echo $'\n'"TrustedUserCAKeys /etc/ssh/pas_ca.pub" >> $src_conf
            r=$?
            if [ $r -ne 0 ];then
                echo "$CENTRIFY_MSG_PREX: Update TrustedUserCAKeys in $src_conf failed!"
                return $r
            fi
            r=1
            case "$OS_NAME" in
            ubuntu)
                if [ "$ssh_from" = "centrifydc" ];then
                    service centrify-sshd restart
                else
                    service ssh restart
                fi
                r=$?
                ;;
            *)
                if [ "$ssh_from" = "centrifydc" ];then
                    sshd_name=centrify-sshd
                else
                    sshd_name=sshd
                fi
                if [ -x /usr/bin/systemctl ]; then
                    systemctl restart $sshd_name.service
                else
                    /etc/init.d/$sshd_name restart
                fi
                r=$?
                ;;
            esac
            return $r
        fi

        return 0
    fi
}

function disable_selinux()
{
    if [ "$CENTRIFYCC_DISABLE_SELINUX" = "yes" ];then
        if [ -f /etc/selinux/config ];then
            /bin/sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
            r=$?
            if [ $r -ne 0 ];then
                echo "$CENTRIFY_MSG_PREX: Disable SELinux in /etc/selinux/config failed!"
                return $r
            fi
        fi
    fi
    return 0
}