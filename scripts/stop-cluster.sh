#!/bin/bash

####################### 
# READ ONLY VARIABLES #
#######################

readonly PROGNAME=`basename "$0"`
readonly SCRIPT_HOME=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

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
      -r | --region)        ... aws region
      -c | --clustername)   ... ocp cluster name

      -d | --dryrun)        ... dryrun
      
      -h | --help)          ... help
    """
}
readonly -f usage_message
[ "$?" -eq "0" ] || return $?


# execute $COMMAND [$DRYRUN=false]
# if command and dryrun=true are provided the command will be execuded
# if command and dryrun=false (or no second argument is provided) 
# the function will only print the command the command to stdout
execute () {
  local exec_command=${1}
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
  local region="eu-central-1"
  local clustername="learningfriday"

  # GETOPT
  OPTS=`getopt -o dhr:c: --long dryrun,help,region:,clustername: -- "$@"`
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
      -c | --clustername) 
        clustername=${2};
        shift 2;
        ;; 
      -r | --region) 
        region=${2};
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
  local instances=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${clustername}-*" "Name=instance-state-name,Values=running" --query Reservations[].Instances[*].InstanceId --region ${region} --output text | tr '\r\n' ' ')
  execute "aws ec2 stop-instances --region ${region} --instance-ids ${instances}"
}
 
main $@