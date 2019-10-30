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
  execute "command -v openshift-install 2&>0 || export PATH=$PATH:${SCRIPT_PARENT_DIR}/bin"
  execute "export KUBECONFIG=${SCRIPT_PARENT_DIR}/install-config/auth/kubeconfig"
  execute "oc whoami"

cat << 'EOF' >$HOME/kubelet-bootstrap-cred-manager-ds.yaml.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
name: kubelet-bootstrap-cred-manager
namespace: openshift-machine-config-operator
labels:
k8s-app: kubelet-bootrap-cred-manager
spec:
replicas: 1
selector:
matchLabels:
k8s-app: kubelet-bootstrap-cred-manager
template:
metadata:
labels:
k8s-app: kubelet-bootstrap-cred-manager
spec:
containers:
- name: kubelet-bootstrap-cred-manager
image: quay.io/openshift/origin-cli:v4.0
command: ['/bin/bash', '-ec']
args:
- |
  #!/bin/bash

  set -eoux pipefail

  while true; do
  unset KUBECONFIG

  echo "----------------------------------------------------------------------"
  echo "Gather info..."
  echo "----------------------------------------------------------------------"
  # context
  intapi=$(oc get infrastructures.config.openshift.io cluster -o "jsonpath={.status.apiServerInternalURI}")
  context="$(oc --config=/etc/kubernetes/kubeconfig config current-context)"
  # cluster
  cluster="$(oc --config=/etc/kubernetes/kubeconfig config view -o "jsonpath={.contexts[?(@.name==\"$context\")].context.cluster}")"
  server="$(oc --config=/etc/kubernetes/kubeconfig config view -o "jsonpath={.clusters[?(@.name==\"$cluster\")].cluster.server}")"
  # token
  ca_crt_data="$(oc get secret -n openshift-machine-config-operator node-bootstrapper-token -o "jsonpath={.data.ca\.crt}" | base64 --decode)"
  namespace="$(oc get secret -n openshift-machine-config-operator node-bootstrapper-token -o "jsonpath={.data.namespace}" | base64 --decode)"
  token="$(oc get secret -n openshift-machine-config-operator node-bootstrapper-token -o "jsonpath={.data.token}" | base64 --decode)"

  echo "----------------------------------------------------------------------"
  echo "Generate kubeconfig"
  echo "----------------------------------------------------------------------"

  export KUBECONFIG="$(mktemp)"
  kubectl config set-credentials "kubelet" --token="$token" >/dev/null
  ca_crt="$(mktemp)"; echo "$ca_crt_data" > $ca_crt
  kubectl config set-cluster $cluster --server="$intapi" --certificate-authority="$ca_crt" --embed-certs >/dev/null
  kubectl config set-context kubelet --cluster="$cluster" --user="kubelet" >/dev/null
  kubectl config use-context kubelet >/dev/null

  echo "----------------------------------------------------------------------"
  echo "Print kubeconfig"
  echo "----------------------------------------------------------------------"
  cat "$KUBECONFIG"

  echo "----------------------------------------------------------------------"
  echo "Whoami?"
  echo "----------------------------------------------------------------------"
  oc whoami
  whoami

  echo "----------------------------------------------------------------------"
  echo "Moving to real kubeconfig"
  echo "----------------------------------------------------------------------"
  cp /etc/kubernetes/kubeconfig /etc/kubernetes/kubeconfig.prev
  chown root:root ${KUBECONFIG}
  chmod 0644 ${KUBECONFIG}
  mv "${KUBECONFIG}" /etc/kubernetes/kubeconfig

  echo "----------------------------------------------------------------------"
  echo "Sleep 60 seconds..."
  echo "----------------------------------------------------------------------"
  sleep 60
  done
securityContext:
  privileged: true
  runAsUser: 0
volumeMounts:
- mountPath: /etc/kubernetes/
name: kubelet-dir
nodeSelector:
node-role.kubernetes.io/master: ""
priorityClassName: "system-cluster-critical"
restartPolicy: Always
securityContext:
runAsUser: 0
tolerations:
- key: "node-role.kubernetes.io/master"
  operator: "Exists"
  effect: "NoSchedule"
- key: "node.kubernetes.io/unreachable"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 120
- key: "node.kubernetes.io/not-ready"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 120
volumes:
- hostPath:
  path: /etc/kubernetes/
  type: Directory
  name: kubelet-dir
EOF

  execute "oc apply -f $HOME/kubelet-bootstrap-cred-manager-ds.yaml.yaml"
  execute "oc delete secrets/csr-signer-signer secrets/csr-signer -n openshift-kube-controller-manager-operator"
  
  execute "watch \"echo -e '+ wait for all clusteroperators to reach status: True False False then exit the script with CTRL + C\n' && oc get clusteroperators\""
}
 
main $@
