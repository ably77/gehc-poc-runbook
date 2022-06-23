[Back to Table of Contents](./README.md) :blue_book:

## Lab1 - Deploy KinD clusters

Ignore the following line.

`Clone this repository and go to the procs directory.`

Note that we are setting region to `us-west` and using separate zones, `us-west-1` and `us-west-2` for each cluster.   This will come into play when we look at locality based failover later.  See more in [Istio documentation](https://istio.io/latest/docs/tasks/traffic-management/locality-load-balancing/failover/).

The use of **metallb** is required for LoadBalancer access to the cluster since it is running inside of Docker.  See more on this in [Kind documentation](https://kind.sigs.k8s.io/docs/user/loadbalancer/).

This guide follows along with the workshop on a Mac (Intel-chipset) and uses the scripts to deploy Kind clusters.  If you want to use k3d, I would recommend using the [demo-infrastructure repo](https://github.com/solo-io/demo-infrastructure) to deploy the typical 3-cluster setup.

Also note that kind on the Mac can be tricky to get ports opened.  If you are having trouble, switch to the k3d setup.  The rest of the field guide will provide instructions where necessary for k3d.

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Introduction](./introduction.md) | [Next - Lab 2 - Deploy Istio](./lab2.md) :arrow_right: |

