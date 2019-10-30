#!/bin/bash

readonly openshift_aws_home=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function openshift-create-aws-dir () {
    if [ ! -d "${openshift_aws_home}/.aws" ]; then
        echo "# create .aws folder in required location"
        echo "+ mkdir -p ${openshift_aws_home}/.aws"
        mkdir -p ${openshift_aws_home}/.aws
    fi
}
readonly -f openshift-create-aws-dir
[ "$?" -eq "0" ] || return $?

# ocp-extract
function ocp-extract () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift gepardec/aws /mnt/openshift/scripts/extract.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-extract
[ "$?" -eq "0" ] || return $?

# ocp-create-config
function ocp-create-config () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift -v ${openshift_aws_home}/.aws:/root/.aws gepardec/aws /mnt/openshift/scripts/create-config.sh"
  openshift-create-aws-dir
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-create-config
[ "$?" -eq "0" ] || return $?

# ocp-create-cluster
function ocp-create-cluster () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift -v ${openshift_aws_home}/.aws:/root/.aws gepardec/aws /mnt/openshift/scripts/create-cluster.sh"
  openshift-create-aws-dir
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-create-cluster
[ "$?" -eq "0" ] || return $?

# ocp-destroy-cluster
function ocp-destroy-cluster () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift -v ${openshift_aws_home}/.aws:/root/.aws gepardec/aws /mnt/openshift/scripts/destroy-cluster.sh"
  openshift-create-aws-dir
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-destroy-cluster
[ "$?" -eq "0" ] || return $?

# ocp-start-cluster
function ocp-start-cluster () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift -v ${openshift_aws_home}/.aws:/root/.aws gepardec/aws /mnt/openshift/scripts/start-cluster.sh"
  openshift-create-aws-dir
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-start-cluster
[ "$?" -eq "0" ] || return $?

# ocp-stop-cluster
function ocp-stop-cluster () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift -v ${openshift_aws_home}/.aws:/root/.aws gepardec/aws /mnt/openshift/scripts/stop-cluster.sh"
  openshift-create-aws-dir
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-stop-cluster
[ "$?" -eq "0" ] || return $?

# ocp-patch-cluster
function ocp-patch-cluster () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift gepardec/aws /mnt/openshift/scripts/patch-cluster.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-patch-cluster
[ "$?" -eq "0" ] || return $?

# ocp-auth-add-google-provider
function ocp-auth-add-google-provider () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift gepardec/aws /mnt/openshift/scripts/auth-add-google-provider.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-auth-add-google-provider
[ "$?" -eq "0" ] || return $?

# ocp-auth-add-cluster-admins
function ocp-auth-add-cluster-admins () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift gepardec/aws /mnt/openshift/scripts/auth-add-cluster-admins.sh"
  echo "+ ${command} $@" && ${command} $@
}
readonly -f ocp-auth-add-cluster-admins
[ "$?" -eq "0" ] || return $?

# ocp-auth-del-kubeadmin
function ocp-auth-del-kubeadmin () {
  local command="docker run --rm -it -e TZ=Europe/Vienna -v ${openshift_aws_home}:/mnt/openshift gepardec/aws /mnt/openshift/scripts/auth-del-kubeadm.sh"
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
