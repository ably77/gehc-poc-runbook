[Back to Table of Contents](./README.md) :blue_book:

## Lab5 - Deploy and register Gloo Mesh

You may recognize that unlike in the workshop for Gloo Mesh 1.x, we are performing a helm install to register the remote clusters with the management plane.  

First, we create the `KubernetesCluster` resource representing the remote cluster.  The name of this resource needs to match the `global.multicluster.clusterName` we gave to Istio on that cluster.  You will also find that the `clusterDomain` here is set to `cluster.local`.  This is dependent on your configuration, but don't change it unless you know what you are doing because this could break routing in the cluster.

Next, we create the `gloo-mesh` namespace on the remote cluster and copy over the certificates from `relay-root-tls-secret` and the key from `relay-identity-token-secret` to create a secure relay registration.

Lastly, the `WorkspaceSettings` is necessary to allow multi-cluster traffic.  This is a new configuration item for GM 2.x that provides label selection for the east-west gateway.

| Previous | Next | 
| :------- | ---: |
| :arrow_left: [Previous - Lab4 - Deploy the httpbin demo app](./lab4.md) | [Next - Lab6 - Create workspaces](./lab6.md) :arrow_right: | 

