[Back to Table of Contents](./README.md) :blue_book:

## Lab9 - Traffic policies

After we create the `RouteTable` for **ratings** let's check for the Istio translation.

```
❯ ./workshops/gloo-mesh/2.x/scripts/find-translation.sh ratings bookinfo-backends             
Looking for Istio translation for ratings in bookinfo-backends
NAME                                                     GATEWAYS   HOSTS                                             AGE
routetable-ratings-bookinfo-backends-cluster1-bookinfo   ["mesh"]   ["ratings.bookinfo-backends.svc.cluster.local"]   36s
```

Interesting!  This time, it created the `VirtualService` in the `bookinfo-backends` namespace.  Why?  

Well, in this case we are configuring east-west routing (routing between two services).  It's not necessary to expose the ratings service to ingress, so we can make this definition part of the **bookinfo** workspace.  This also shows that you do not need to create all Gloo Mesh resources in the root namespace of the `Workspace`.

If we look at the details of this `VirtualService` there are a couple interesting things to point out.

```
❯ k get virtualservice routetable-ratings-bookinfo-backends-cluster1-bookinfo -n bookinfo-backends -oyaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  creationTimestamp: "2022-04-02T01:43:26Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-backends
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: RouteTable
    gloo.solo.io/parent_name: ratings
    gloo.solo.io/parent_namespace: bookinfo-backends
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: routetable-ratings-bookinfo-backends-cluster1-bookinfo
  namespace: bookinfo-backends
  resourceVersion: "383399"
  uid: e136331b-9acf-49a1-9f3e-406c9567d77c
spec:
  exportTo:
  - .
  gateways:
  - mesh
  hosts:
  - ratings.bookinfo-backends.svc.cluster.local
  http:
  - fault:
      delay:
        fixedDelay: 2s
        percentage:
          value: 100
    match:
    - sourceLabels:
        app: reviews
      uri:
        prefix: /
    name: ratings-ratings
    route:
    - destination:
        host: ratings.bookinfo-backends.svc.cluster.local
        port:
          number: 9080
```

First, you will see our old friend `exportTo` preventing leakage of this configuration.  You may be surprised to see that it is not exposed to all namespaces within the `Workspace`.  The other interesting bit is that the `gateways` list has a single entry of `mesh`.  Checking Istio's documentation on [VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/#VirtualService) shows that `mesh` is a reserved word used to imply all the sidecars in the mesh.  

Also, note that `Policies` by themselves do not have any meaning without a routing resource to attach to.  

After creating the retry policy and corresponding `RouteTable` let's check our created Istio translations.

```
❯ ./workshops/gloo-mesh/2.x/scripts/find-translation.sh reviews bookinfo-backends
Looking for Istio translation for reviews in bookinfo-backends
Looking for objects of type authorizationpolicies.security.istio.io
Looking for objects of type workloadentries.networking.istio.io
Looking for objects of type envoyfilters.networking.istio.io
Looking for objects of type sidecars.networking.istio.io
Looking for objects of type serviceentries.networking.istio.io
Looking for objects of type requestauthentications.security.istio.io
Looking for objects of type virtualservices.networking.istio.io
NAME                                                     GATEWAYS   HOSTS                                             AGE
routetable-reviews-bookinfo-backends-cluster1-bookinfo   ["mesh"]   ["reviews.bookinfo-backends.svc.cluster.local"]   4m52s
Looking for objects of type destinationrules.networking.istio.io
NAME                                                              HOST                                          AGE
reviews-bookinfo-backends-svc-c-30c18d19a286296c129f54ce23fec54   reviews.bookinfo-backends.svc.cluster.local   4m54s
Looking for objects of type gateways.networking.istio.io
Looking for objects of type telemetries.telemetry.istio.io
Looking for objects of type peerauthentications.security.istio.io
Looking for objects of type workloadgroups.networking.istio.io
Looking for objects of type istiooperators.install.istio.io
```

Oh, interesting!  There's two translations.  Let's take a peek at the `DestinationRule`.

```
❯ k get dr reviews-bookinfo-backends-svc-c-30c18d19a286296c129f54ce23fec54 -n bookinfo-backends -oyaml   
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  creationTimestamp: "2022-04-02T01:56:46Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-backends
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: ""
    gloo.solo.io/parent_kind: Service
    gloo.solo.io/parent_name: reviews
    gloo.solo.io/parent_namespace: bookinfo-backends
    gloo.solo.io/parent_version: v1
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: reviews-bookinfo-backends-svc-c-30c18d19a286296c129f54ce23fec54
  namespace: bookinfo-backends
  resourceVersion: "385089"
  uid: 83ddbe26-c67f-4192-ac81-715cde6e63bc
spec:
  exportTo:
  - .
  host: reviews.bookinfo-backends.svc.cluster.local
  subsets:
  - labels:
      version: v2
    name: version-v2
```

Since we setup our `forwardTo` with subset routing, Gloo Mesh created the corresponding `DestinationRule` for us.

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab8 - Expose the productpage through a gateway](./lab8.md) | [Next - Lab10 - Create the Root Trust Policy](./lab10.md) :arrow_right: |

