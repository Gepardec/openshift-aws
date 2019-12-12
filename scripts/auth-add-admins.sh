#!/bin/bash

#######################
# READ ONLY VARIABLES #
#######################

readonly PROGNAME=`basename "$0"`
readonly SCRIPT_HOME=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
readonly SCRIPT_PARENT_DIR=$( cd ${SCRIPT_HOME} && cd .. && pwd )

####################
# GLOBAL VARIABLES #
####################

FLAG_DRYRUN=false

##########
# SOURCE #
##########

# source other bash scripts here

##########
# SCRIPT #
##########

usage_message () {
  echo """Usage:
    $PROGNAME [OPT ..]
      -u | --users)    ... specify a user file (default: admins)

      -d | --dryrun)   ... dryrun

      -h | --help)     ... help"""
}
readonly -f usage_message
[ "$?" -eq "0" ] || return $?


# execute $COMMAND [$DRYRUN=false]
# if command and dryrun=true are provided the command will be execuded
# if command and dryrun=false (or no second argument is provided)
# the function will only print the command the command to stdout
execute () {
  local exec_command=$1
  local flag_dryrun=${2:-$FLAG_DRYRUN}

  if [[ "${flag_dryrun}" == false ]]; then
     echo "+ ${exec_command}"
     eval "${exec_command}"
  else
    echo "${exec_command}"
  fi
}
# readonly definition of a function throws an error if another function
# with the same name is defined a second time
readonly -f execute
[ "$?" -eq "0" ] || return $?

main () {
  # INITIAL VALUES
  local users="admins"

  # GETOPT
  OPTS=`getopt -o dhu: --long dryrun,help,users: -- "$@"`
  if [ $? != 0 ]; then
    print_stderr "failed to fetch options via getopt"
    exit $EXIT_FAILURE
  fi
  eval set -- "$OPTS"
  while true ; do
    case "$1" in
      -d | --dryrun)
        FLAG_DRYRUN=true;
        shift;
        ;;
      -u | --users)
        users=${2};
        shift 2;
        ;;
      -h | --help)
        usage_message;
        exit 0;
        ;;
      *)
        break
        ;;
    esac
  done

  ####
  # CHECK INPUT
  # check if all required options are given

  ####
  # CORE LOGIC

  execute "command -v oc 2&>0 || export PATH=$PATH:${SCRIPT_PARENT_DIR}/bin"
  execute "export KUBECONFIG=${SCRIPT_PARENT_DIR}/install-config/auth/kubeconfig"
  execute "oc whoami"
  execute "oc adm groups new admins"
  execute "oc adm policy add-cluster-role-to-group admin admins"

  while read user; do
    execute "oc adm groups add-users admins ${user}"
  done < "${SCRIPT_PARENT_DIR}/${users}"

  execute "oc get group"
}

main $@

