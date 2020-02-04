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
  execute "command -v oc 2&>0 || export PATH=$PATH:${SCRIPT_PARENT_DIR}/bin"
  if [[ -f ${SCRIPT_PARENT_DIR}/install-config/auth/kubeconfig ]]; then
    execute "export KUBECONFIG=${SCRIPT_PARENT_DIR}/install-config/auth/kubeconfig"
  fi
  execute "oc whoami"
  
  TIMESTAMP=$(date +%Y%m%d%H%M%S)
  execute """
    export CERTDIR=/mnt/openshift/letsencrypt
    mkdir -p /root/.acme.sh \${CERTDIR}
    export AWS_ACCESS_KEY_ID=\$(cat ~/.aws/credentials | /usr/bin/grep 'aws_access_key_id = ' | sed 's/aws_access_key_id = //g') && \
    export AWS_SECRET_ACCESS_KEY=\$(cat ~/.aws/credentials | /usr/bin/grep 'aws_secret_access_key = ' | sed 's/aws_secret_access_key = //g') && \
    export LE_API=\$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././') && \
    export LE_WILDCARD=\$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}') && \
    
    #${SCRIPT_HOME}/acme.sh/acme.sh --issue -d \${LE_API} -d *.\${LE_WILDCARD} --dns dns_aws && \
    cp -R /root/.acme.sh/\${LE_API}/* \${CERTDIR} && \

    oc -n openshift-ingress label secrets -l letsencrypt=true --overwrite delete=me && \
    oc -n openshift-ingress create secret tls router-certs-${TIMESTAMP} --cert=\${CERTDIR}/fullchain.cer --key=\${CERTDIR}/\${LE_API}.key && \
    oc -n openshift-ingress label secrets router-certs-${TIMESTAMP} letsencrypt=true &&  \
    
    oc -n openshift-ingress-operator patch ingresscontroller default --type=merge --patch='{\"spec\": { \"defaultCertificate\": { \"name\": \"router-certs-${TIMESTAMP}\" }}}' && \
    oc -n openshift-ingress delete secrets -l delete=me
  """
}
 
main $@
