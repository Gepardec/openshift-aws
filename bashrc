#!/bin/bash

readonly openshift_aws_home=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function __openshift-aws-create-dirs () {
    if [ ! -d "${openshift_aws_home}/.aws" ]; then
        echo "# create .aws folder"
        echo "+ mkdir -p ${openshift_aws_home}/.aws"
        mkdir -p ${openshift_aws_home}/.aws
    fi
    if [ ! -d "$(echo ~)/.kube" ]; then
        echo "# create .kube folder"
        echo "+ mkdir -p $(echo ~)/.kube"
        mkdir -p $(echo ~)/.kube
    fi
}
readonly -f __openshift-aws-create-dirs
[ "$?" -eq "0" ] || return $?

# ocp-extract
function ocp-extract () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  gepardec/awscli \
                  /mnt/openshift/scripts/extract.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-extract
[ "$?" -eq "0" ] || return $?

# ocp-create-config
function ocp-create-config () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  -v ${openshift_aws_home}/.aws:/.aws \
                  gepardec/awscli \
                  /mnt/openshift/scripts/create-config.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-create-config
[ "$?" -eq "0" ] || return $?

# ocp-create-cluster
function ocp-create-cluster () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                -v ${openshift_aws_home}:/mnt/openshift \
                -v ${openshift_aws_home}/.aws:/.aws \
                gepardec/awscli \
                /mnt/openshift/scripts/create-cluster.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-create-cluster
[ "$?" -eq "0" ] || return $?

# ocp-destroy-cluster
function ocp-destroy-cluster () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  -v ${openshift_aws_home}/.aws:/.aws \
                  gepardec/awscli \
                  /mnt/openshift/scripts/destroy-cluster.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-destroy-cluster
[ "$?" -eq "0" ] || return $?

# ocp-start-cluster
function ocp-start-cluster () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  -v ${openshift_aws_home}/.aws:/.aws \
                  gepardec/awscli \
                  /mnt/openshift/scripts/start-cluster.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-start-cluster
[ "$?" -eq "0" ] || return $?

# ocp-stop-cluster
function ocp-stop-cluster () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  -v ${openshift_aws_home}/.aws:/.aws \
                  gepardec/awscli \
                  /mnt/openshift/scripts/stop-cluster.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-stop-cluster
[ "$?" -eq "0" ] || return $?

# ocp-patch-cluster
function ocp-patch-cluster () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  -v $(echo ~)/.kube/:/.kube \
                  gepardec/awscli \
                  /mnt/openshift/scripts/patch-cluster.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-patch-cluster
[ "$?" -eq "0" ] || return $?

# ocp-auth-add-google-provider
function ocp-auth-add-google-provider () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  -v $(echo ~)/.kube/:/.kube \
                  gepardec/awscli \
                  /mnt/openshift/scripts/auth-add-google-provider.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-auth-add-google-provider
[ "$?" -eq "0" ] || return $?

# ocp-auth-add-cluster-admins
function ocp-auth-add-cluster-admins () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  -v $(echo ~)/.kube/:/.kube \
                  gepardec/awscli \
                  /mnt/openshift/scripts/auth-add-cluster-admins.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-auth-add-cluster-admins
[ "$?" -eq "0" ] || return $?

# ocp-auth-add-admins
function ocp-auth-add-admins () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  -v $(echo ~)/.kube/:/.kube \
                  gepardec/awscli \
                  /mnt/openshift/scripts/auth-add-admins.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-auth-add-admins
[ "$?" -eq "0" ] || return $?

# ocp-auth-del-kubeadmin
function ocp-auth-del-kubeadmin () {
  __openshift-aws-create-dirs
  local command="docker run --rm -it -e TZ=Europe/Vienna \
                  -v ${openshift_aws_home}:/mnt/openshift \
                  -v $(echo ~)/.kube/:/.kube \
                  gepardec/awscli \
                  /mnt/openshift/scripts/auth-del-kubeadm.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-auth-del-kubeadmin
[ "$?" -eq "0" ] || return $?

# ocp-setup
function ocp-setup () {
  ocp-extract
  ocp-create-cluster
  ocp-auth-add-google-provider
  ocp-auth-add-cluster-admins
  ocp-auth-del-kubeadmin
  ocp-patch-cluster
}
readonly -f ocp-setup
[ "$?" -eq "0" ] || return $?
