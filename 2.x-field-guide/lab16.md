[Back to Table of Contents](./README.md) :blue_book:

## Lab16 - Deploy Keycloak

This lab is pretty straightforward.  We are using Keycloak since it is open source and has the OIDC features we need.  If you are using the demo infrastructure k3d setup, you will need to find the loadBalancer node and edit it to add a port for Keycloak.  Something like the following.

```
❯ k3d node list                 
NAME                    ROLE           CLUSTER    STATUS
k3d-cluster1-server-0   server         cluster1   running
k3d-cluster1-serverlb   loadbalancer   cluster1   running
k3d-cluster2-server-0   server         cluster2   running
k3d-cluster2-serverlb   loadbalancer   cluster2   running
k3d-mgmt-server-0       server         mgmt       running
k3d-mgmt-serverlb       loadbalancer   mgmt       running

❯ k3d node edit k3d-cluster1-serverlb --port-add 18080:8080
INFO[0000] Renaming existing node k3d-cluster1-serverlb to k3d-cluster1-serverlb-TTMtj... 
INFO[0000] Creating new node k3d-cluster1-serverlb...   
INFO[0000] Stopping existing node k3d-cluster1-serverlb-TTMtj... 
INFO[0010] Starting new node k3d-cluster1-serverlb...   
INFO[0010] Starting Node 'k3d-cluster1-serverlb'        
INFO[0016] Deleting old node k3d-cluster1-serverlb-TTMtj... 
INFO[0016] Successfully updated k3d-cluster1-serverlb-TTMtj 
```

Then you can use `localhost:18080` for the **ENDPOINT_KEYCLOAK** variable.

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab15 - Expose an external service](./lab15.md) | [Next - Lab17 - Securing the access with OAuth](./lab17.md) :arrow_right: |