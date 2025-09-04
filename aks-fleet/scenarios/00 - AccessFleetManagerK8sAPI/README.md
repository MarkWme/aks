# Access the Kubernetes API for the hub cluster

The script in this folder will connect to the hub cluster and get the kubeconfig file. It will also assign a cluster admin role to the currently logged in user. Once this is done, you will be able to access the Kubernetes API and run `kubectl` commands against the hub cluster.
