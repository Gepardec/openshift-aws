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

  # GETOPT
  OPTS=`getopt -o dh --long dryrun,help -- "$@"`
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
  set -e
  execute "mkdir -p ${SCRIPT_PARENT_DIR}/bin/"
  execute "tar -xvzf ${SCRIPT_PARENT_DIR}/openshift-client-linux-*.tar.gz -C ${SCRIPT_PARENT_DIR}/bin/"
  execute "tar -xvzf ${SCRIPT_PARENT_DIR}/openshift-install-linux-*.tar.gz -C ${SCRIPT_PARENT_DIR}/bin/"
}
 
main $@