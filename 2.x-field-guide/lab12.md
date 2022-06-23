[Back to Table of Contents](./README.md) :blue_book:

## Lab12 - Leverage Virtual Destinations

In case you missed it, the `spec.workloads.selector[0].cluster` was removed from the north-south-gw `Gateway`.

Let's see what was created by the productpage `VirtualDestination`.

```
❯ ./scripts/find-translation.sh productpage bookinfo-frontends
Looking for Istio translation for productpage in bookinfo-frontends
Looking for objects of type requestauthentications.security.istio.io
Looking for objects of type wasmplugins.extensions.istio.io
Looking for objects of type workloadgroups.networking.istio.io
Looking for objects of type telemetries.telemetry.istio.io
Looking for objects of type gateways.networking.istio.io
Looking for objects of type workloadentries.networking.istio.io
NAME                                                        AGE   ADDRESS
vd-productpage-global-bookinfo-app-productpage-172-23-0-6   52s   172.23.0.6
Looking for objects of type virtualservices.networking.istio.io
Looking for objects of type envoyfilters.networking.istio.io
Looking for objects of type serviceentries.networking.istio.io
NAME                             HOSTS                    LOCATION        RESOLUTION   AGE
vd-productpage-global-bookinfo   ["productpage.global"]   MESH_INTERNAL   STATIC       59s
Looking for objects of type peerauthentications.security.istio.io
Looking for objects of type sidecars.networking.istio.io
Looking for objects of type destinationrules.networking.istio.io
NAME                                                              HOST                 AGE
productpage-global-virtual-dest-a65c94ffce21a1199563fc5d06cd3ad   productpage.global   67s
Looking for objects of type authorizationpolicies.security.istio.io
Looking for objects of type istiooperators.install.istio.io
```

Let's first look at the `WorkloadEntry`.

```
❯ k get workloadentry -n bookinfo-frontends vd-productpage-global-bookinfo-app-productpage-172-23-0-6 -oyaml                                                         
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  creationTimestamp: "2022-05-03T15:54:40Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    app: productpage
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-frontends
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: VirtualDestination
    gloo.solo.io/parent_name: productpage
    gloo.solo.io/parent_namespace: bookinfo-frontends
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: vd-productpage-global-bookinfo-app-productpage-172-23-0-6
  namespace: bookinfo-frontends
  resourceVersion: "749548"
  uid: d6e4337d-3ee2-439e-9da0-865babf470e4
spec:
  address: 172.23.0.6
  labels:
    app: productpage
  locality: us-east-1
  ports:
    http-9080: 15443
```

If you look at the Istio [documentation on WorkloadEntry]
(https://istio.io/latest/docs/reference/config/networking/workload-entry/), you will find that it describes routing capabilities for non-Kubernetes entities.  Gloo Mesh leverages this capability for multicluster routing through a TLS PASSTHROUGH port however.  Critical to locality based load-balancing here is the `locality` field.  You can find out more about [locality based load-balancing](https://istio.io/latest/docs/tasks/traffic-management/locality-load-balancing/) in Istio's documentation.

Now, let's check out the `ServiceEntry`.

```
❯ k get serviceentry -n bookinfo-frontends vd-productpage-global-bookinfo -oyaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  creationTimestamp: "2022-04-02T15:50:57Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-frontends
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: VirtualDestination
    gloo.solo.io/parent_name: productpage
    gloo.solo.io/parent_namespace: bookinfo-frontends
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: vd-productpage-global-bookinfo
  namespace: bookinfo-frontends
  resourceVersion: "491522"
  uid: 1b71882f-fbf9-42d5-a277-39b9d5818d43
spec:
  addresses:
  - 254.154.115.171
  exportTo:
  - bookinfo-backends
  - bookinfo-frontends
  - gloo-mesh-addons
  - istio-gateways
  hosts:
  - productpage.global
  location: MESH_INTERNAL
  ports:
  - name: http-9080
    number: 9080
    protocol: HTTP
  resolution: STATIC
  workloadSelector:
    labels:
      app: productpage
```

Underneath the covers, we would expect to find a cluster configured with the fqdn of "productpage.global".

```
❯ istioctl pc clusters productpage-v1-69f8699b74-j7rxj.bookinfo-frontends | grep productpage
productpage.bookinfo-frontends.svc.cluster.local           9080      -              outbound      EDS              
productpage.global                                         9080      -              outbound      EDS              productpage-global-virtual-dest-a65c94ffce21a1199563fc5d06cd3ad.bookinfo-frontends
```

This fqdn points to an endpoint defined by the `VirtualDestination`.  

Finally, let's look at the `DestinationRule`.

```
❯ k get dr -n bookinfo-frontends productpage-global-virtual-dest-a65c94ffce21a1199563fc5d06cd3ad -oyaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  creationTimestamp: "2022-04-02T15:50:57Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-frontends
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: VirtualDestination
    gloo.solo.io/parent_name: productpage
    gloo.solo.io/parent_namespace: bookinfo-frontends
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: productpage-global-virtual-dest-a65c94ffce21a1199563fc5d06cd3ad
  namespace: bookinfo-frontends
  resourceVersion: "491521"
  uid: 235eda8e-c29a-49ab-ae01-9afb291fd2e6
spec:
  exportTo:
  - bookinfo-backends
  - bookinfo-frontends
  - gloo-mesh-addons
  - istio-gateways
  host: productpage.global
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 9080
      tls:
        mode: ISTIO_MUTUAL
        subjectAltNames:
        - spiffe://cluster1/ns/bookinfo-frontends/sa/bookinfo-productpage
        - spiffe://cluster2/ns/bookinfo-frontends/sa/bookinfo-productpage
```

Now, what happens when we apply this `VirtualDestination` to a `RouteTable`?

Again, this will be applied to the `VirtualService` in the istio-gateways namespace since we are exporting this configuration to the `Workspace` where the `VirtualGateway` lives.

```
❯ k get virtualservice -n istio-gateways routetable-productpage-bookinfo-frontends-cluster1-gateways -oyaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  creationTimestamp: "2022-04-02T01:21:46Z"
  generation: 2
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: istio-gateways
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: RouteTable
    gloo.solo.io/parent_name: productpage
    gloo.solo.io/parent_namespace: bookinfo-frontends
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: routetable-productpage-bookinfo-frontends-cluster1-gateways
  namespace: istio-gateways
  resourceVersion: "493641"
  uid: 23e47a74-c083-4756-82d1-4eb722eae599
spec:
  exportTo:
  - .
  gateways:
  - virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738
  hosts:
  - '*'
  http:
  - match:
    - sourceLabels:
        app: istio-ingressgateway
        istio: ingressgateway
      uri:
        exact: /productpage
    - sourceLabels:
        app: istio-ingressgateway
        istio: ingressgateway
      uri:
        prefix: /static
    - sourceLabels:
        app: istio-ingressgateway
        istio: ingressgateway
      uri:
        exact: /login
    - sourceLabels:
        app: istio-ingressgateway
        istio: ingressgateway
      uri:
        exact: /logout
    - sourceLabels:
        app: istio-ingressgateway
        istio: ingressgateway
      uri:
        prefix: /api/v1/products
    name: productpage-productpage
    route:
    - destination:
        host: productpage.global
        port:
          number: 9080
```

Now, you can see the destination host selected is the global one.

### Failover

Let's take a look at the `DestinationRule` after we have applied our policies to the `VirtualDestination`.

```
❯ k get dr -n bookinfo-frontends productpage-global-virtual-dest-a65c94ffce21a1199563fc5d06cd3ad -oyaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  creationTimestamp: "2022-04-02T15:50:57Z"
  generation: 2
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-frontends
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: VirtualDestination
    gloo.solo.io/parent_name: productpage
    gloo.solo.io/parent_namespace: bookinfo-frontends
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: productpage-global-virtual-dest-a65c94ffce21a1199563fc5d06cd3ad
  namespace: bookinfo-frontends
  resourceVersion: "500719"
  uid: 235eda8e-c29a-49ab-ae01-9afb291fd2e6
spec:
  exportTo:
  - bookinfo-backends
  - bookinfo-frontends
  - gloo-mesh-addons
  - istio-gateways
  host: productpage.global
  trafficPolicy:
    portLevelSettings:
    - loadBalancer:
        localityLbSetting:
          enabled: true
      outlierDetection:
        baseEjectionTime: 30s
        consecutive5xxErrors: 2
        interval: 5s
        maxEjectionPercent: 100
      port:
        number: 9080
      tls:
        mode: ISTIO_MUTUAL
        subjectAltNames:
        - spiffe://cluster1/ns/bookinfo-frontends/sa/bookinfo-productpage
        - spiffe://cluster2/ns/bookinfo-frontends/sa/bookinfo-productpage

```

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab11 - Multi-cluster Traffic](./lab11.md) | [Next - Lab13 - Zero Trust](./lab13.md) :arrow_right: | 

