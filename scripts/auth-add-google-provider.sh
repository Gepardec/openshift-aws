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
      -o | --hostedomain ... allow google logins only from this domain

      -d | --dryrun)     ... dryrun
      
      -h | --help)       ... help
"""
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
  local hostedDomain="gepardec.com"

  # GETOPT
  OPTS=`getopt -o dho: --long dryrun,--hosteddomain:,help -- "$@"`
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

  if [ ! -f "${SCRIPT_PARENT_DIR}/clientID" ]; then
    >&2 echo "${SCRIPT_PARENT_DIR}/clientID not found"
    exit 1
  else 
    local clientID=$(cat ${SCRIPT_PARENT_DIR}/clientID)
  fi   
  
  if [ ! -f "${SCRIPT_PARENT_DIR}/clientSecret" ]; then
    >&2 echo "${SCRIPT_PARENT_DIR}/clientSecret not found"
    exit 1
  fi 
  
  ####
  # CORE LOGIC
readonly local oauth_yaml="""
"""

  execute "command -v oc 2&>0 || export PATH=$PATH:${SCRIPT_PARENT_DIR}/bin"
  if [[ -f /.kube/config ]]; then
    export KUBECONFIG=/.kube/config
  else
    export KUBECONFIG=${SCRIPT_PARENT_DIR}/install-config/auth/kubeconfig
  fi
  execute "oc whoami"
  execute "oc create secret generic google-auth-secret --from-file=clientSecret=${SCRIPT_PARENT_DIR}/clientSecret -n openshift-config"
  execute """cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: google
    mappingMethod: claim 
    type: Google
    google:
      clientID: ${clientID}
      clientSecret: 
        name: google-auth-secret
      hostedDomain: \"${hostedDomain}\"
EOF
"""
}
 
main $@







