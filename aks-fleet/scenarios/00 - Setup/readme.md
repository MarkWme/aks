# Setup

Some of the scenarios in this repository are designed to show you that applications are running in different AKS clusters within the fleet and will display which cluster they are running on. There's no easy way to get this information from the Kubernetes API, so we do this by creating a configMap in each cluster that contains the name of the cluster.

The setup.sh script will configure this configMap in each cluster. It will also set up the appropriate role assignments so that the currently logged in user can access the Kubernetes API for the hub cluster and retrieve the credentials for the Fleet Manager hub cluster.
