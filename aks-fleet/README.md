# AKS Fleet Management

## Overview

This deployment script will create the following resources

- 2 x virtual networks in two different Azure regions
- Subnets in the virtual networks. One subnet will be for the AKS nodes. Additional subnets will be created for each cluster to be the pod subnet. For example, in a three cluster deployment, you will get four subnets in each virtual network. One subnet will contain all of the nodes for all three clusters, then each cluster will have a separate subnet for its pods.
- A managed identity for each cluster.
- 2 sets of AKS deployments, with an equal number of clusters being deployed to different Azure regions.

## Tasks

Below are links to walkthroughs of scenarios that can be tested with this deployment.

- [Access the Kubernetes API for the hub cluster](./scenarios/AccessFleetManagerK8sAPI/README.md)

## Problems

Due to some issues with how subnets are provisioned by the Azure Resource Manager, it does not appear to be possible to redeploy this template in an idempotent way. It seems that when the subnets are first defined, all is well. When AKS is first deployed to that subnet, it creates a delegation. When attempting to redeploy the template, it seems that the presence of the delegation causes an error, possibly because the deployment process tries to remove the delegation because it's not part of the deployment template. I tried to add the delegation to the template, which then fixes the redeploy scenario but breaks the initial deployment scenario as AKS fails because it can't be deployed to a subnet that has existing delegations, even if it is an AKS delegation.

## To Do

- Attach ACR to each of the clusters during deployment
- Peer the virtual networks
- Assign dev/test/prod Update Groups during deployment