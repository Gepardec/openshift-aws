![GitHub](https://img.shields.io/github/license/gepardec/openshift-aws)
![Maintenance](https://img.shields.io/maintenance/yes/2019)

<p align="right">
<img alt="gepardec" width=100px src="https://github.com/Gepardec/openshift-aws/raw/master/.images/gepardec.png">
</p>
<br>
<br>
<p align="center">
<img alt="logos" width=400px src="https://github.com/Gepardec/openshift-aws/raw/master/.images/logos.png">
</p>
<br>

Installing OpenShift on AWS is already quite simple. If you do not plan to do it often, you can easily live with the manual steps involved in the initial setup. For us it is important to easily 

* create an OpenShift cluster
* patch it to allow shutdown within 24h
* add google as auth provider
* add new cluster admins
* delete kubeadmin user
* start / stop cluster VMs
* destroy the OpenShift cluster.

In order to do that frequently we have created a collection of scripts and alias to help us be as efficient as we can be. If you have a similar need, we hope our work will help you speed up your manual setup steps for you.

## Preflight

In general we will follow https://cloud.redhat.com/openshift/install/aws/installer-provisioned to provision OpenShift on AWS.

All aliases that we have created are defined in the bashrc and listed below. To use the alias you need to source the bashrc. If you wish to run the commands independent without the alias, you can do so on your own risk. 

```bash
source ./bashrc
```

## Available commands

```
ocp-extract

ocp-create-config

ocp-create-cluster
ocp-destroy-cluster

ocp-patch-cluster

ocp-start-cluster
ocp-stop-cluster

ocp-auth-add-google-provider
ocp-auth-add-cluster-admins
ocp-auth-del-kubeadmin

ocp-setup
```

**Hint:** do not forget to source the bashrc

---

## Create new cluster

### 1) Extract folders

To create a new cluster on AWS we need to use RedHat's new installer for OpenShift 4. First download installer, pull-secret and command-line tools and store the files in the repo folder.

Download Link: https://cloud.redhat.com/openshift/install/aws/installer-provisioned

Next we can use `ocp-extract`to extract the tar files into a new `bin` folder.

**Hint:** use `--help` to learn more about `ocp-extract`

```bash
ocp-extract
```

### 2) create config

For this step you will need an AWS account. More info can be found here

* [Configure an AWS account](https://docs.openshift.com/container-platform/4.2/installing/installing_aws/installing-aws-account.html)

Once you execute the command, you will get the chance to interactively create your initial config.

**Hint:** use `--help` to learn more about `ocp-create-config`

```bash
ocp-create-config
```

### 3) customize config 

Feel free to customize the install-config to your requirements. Here a few links that can help along the way

* [Installation configuration parameters for AWS](https://docs.openshift.com/container-platform/4.2/installing/installing_aws/installing-aws-customizations.html#installation-configuration-parameters_installing-aws-customizations)
* [Sample customized install-config.yaml file for AWS](https://docs.openshift.com/container-platform/4.2/installing/installing_aws/installing-aws-customizations.html#installation-aws-config-yaml_installing-aws-customizations)
* [Customizing your network configuration](https://docs.openshift.com/container-platform/4.2/installing/installing_aws/installing-aws-network-customizations.html)

### 4) create cluster

Once your config is to your liking, you can create the cluster simply by running

**Hint:** use `--help` to learn more about `ocp-create-cluster`

```bash
ocp-create-cluster
```

---

## Patch cluster

> When installing OpenShift 4 clusters a bootstrap certificate is created
that is used on the master nodes to create certificate signing requests
(CSRs) for kubelet client certificates (one for each kubelet) that will
be used to identify each kubelet on any node.<br>
> Because certificates can not be revoked, this certificate is made with a
short expire time and 24 hours after cluster installation, it can not be
used again. All nodes other than the master nodes have a service account
token which is revocable. Therefore the bootstrap certificate is only
valid for 24 hours after cluster installation. After then again every 30
days.<br>
> If the master kubelets do not have a 30 day client certificate (the
first only lasts 24 hours), then missing the kubelet client certificate
refresh window renders the cluster unusable because the bootstrap
credential cannot be used when the cluster is woken back up.
Practically, this requires an OpenShift 4 cluster to be running for at
least 25 hours after installation before it can be shut down.<br>
> The following process enables cluster shutdown right after installation.
It also enables cluster resume at any time in the next 30 days.<br>
> https://blog.openshift.com/enabling-openshift-4-clusters-to-stop-and-resume-cluster-vms/

Okay, now let's do exactly what the OpenShift blog post describes and patch the cluster to allow shutdown before 24h have passed.

**Hint:** use `--help` to learn more about `ocp-patch-cluster`

```bash
ocp-patch-cluster
```

**Pitfall:** after the script succeeded you need to execute `oc get clusteroperators` and wait for all clusteroperators to reach the required status (True False False).

---

## Add google auth to cluster

You will need OAuth2.0 credential IDs from google to execute this step.

To create or get the clientID / clientSecret use Google's developer console: https://console.developers.google.com/apis/credentials

Once you have the clientID and clientSecret, store them as files (`clientID` and `clientSecret`) in the repo directory.

**Hint:** file names are case-sensitive

Once the `clientID` and `clientSecret` are in place we can run the command to add google as an authentication provider to the OpenShift cluster. The default will allow gepardec.com users access to the cluster. You can alter the behavior via `--hosteddomain=<your-domain.com>`. 

**Hint:** use `--help` to learn more about `ocp-auth-add-google-provider`

```bash
ocp-auth-add-google-provider
```

## Add new cluster admins

To add cluster admins to your cluster you can use `ocp-auth-add-cluster-admins`. It will create a new cluster-admins group and add a list of users to that group. Unless specified via options it will read `cluster-admins` in the repo directory. Specify one user per line like this:

```
user1
user2
```

**Hint:** leave an empty newline at the end of the file. Otherwise, the last entry will be skipped.

**Hint:** use `--help` to learn more about `ocp-auth-add-cluster-admins`

```bash
ocp-auth-add-cluster-admins
```

---

## Stop cluster

To start a running cluster you can use `ocp-stop-cluster`.

**Hint:** use `--help` to learn more about `ocp-stop-cluster`

```bash
ocp-stop-cluster
```

---

## Start cluster

To start a stopped cluster again you can use `ocp-start-cluster`.

**Hint:** use `--help` to learn more about `ocp-start-cluster`

```bash
ocp-start-cluster
```

---

## Destroy cluster

Destroy all AWS resources created by `ocp-create-cluster`.

**Hint:** manually added resources will not be deleted!

**Hint:** use `--help` to learn more about `ocp-destroy-cluster`

```bash
ocp-destroy-cluster
```

--- 
## All in one

In order to execute the bootstrapping process quickly you can run `ocp-setup`.

**Hint:** this will run the above commands with the default values. If you want to alter the behavior, alter the ocp-setup function in your copy of the bashrc by introducing additional options to the commands.

```bash
ocp-setup
```

---

# Bootstrap AWS Cluster with Travis

## General Travis repo settings

* Build pushed branches: **Disabled**
* Build pushed pull requests: **Disabled**

## Common Playground Cluster

The master branch can create / destroy / recreate our common playground cluster located at

***.p.aws.ocp.gepardec.com**

and is treated as a productive cluster a target uptime of 24/7.

## Additonal clusters

Additional clusters can be created as needed. Currently available cluster names are:

* 1
* 2
* 3

### 1) Choose a Clustername

To use one of those names for your cluster please add the purpose and maintainer for the cluster to this readme in **master**.

### 2) New Branch

Next you will need to branch your configuration from master.

```
git checkout master
git branch -b cluster/1
```

### 3) Set Clustername

In `.travis.yml` you need to change the `CLUSTER_NAME` to the value of your choice (1,2,3).

```
env:
  global:
    - CLUSTER_NAME=1
    - CLUSTER_CREATE=true
```

Commit your changes and push

```
git commit -am "create new ocp cluster (1) on aws"
git push
```

### 4) Trigger cluster creation

Manually trigger the build for your branch in travis.

https://travis-ci.com/gepardec/openshift-aws

---

## Breaking Change: Alter config files

To alter more config you can copy the Repo from our NAS /Repositories/bla/blub
change the configs to your hearts content, encrypt them with `update_secrets.tar`.

Running `update_secrets.sh` will invalidate any previous encrypted secret in any branch!

---

### Sources:

* https://cloud.redhat.com/openshift/install/aws/installer-provisioned
* https://blog.openshift.com/enabling-openshift-4-clusters-to-stop-and-resume-cluster-vms/
* https://docs.openshift.com/container-platform/4.1/authentication/identity_providers/configuring-google-identity-provider.html
