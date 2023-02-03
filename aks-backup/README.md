# AKS Backup

Testing AKS Backup options.

This will deploy two clusters, which can then be used to test moving data / state between clusters

Use the `simpleapi.yaml` file in the `k8s` folder to deploy a sample application with a PV attached

> The application doesn't write anything to disk yet, so you can use something like `kubectl exec` to access the cluster and write something to the mounted storage as a test

In the Azure Portal, find the Azure Disk that backs the PV. Take a snapshot of that disk. Then create a new disk in the MC_ resource group of the target cluster, using the snapshot as the source.

Finally, use the `simpleapi-restored.yaml` file to deploy a sample application that deploys to the new Azure Disk that you've created. 

