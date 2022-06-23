[Back to Table of Contents](./README.md) :blue_book:

## Lab8 - Expose the productpage through a gateway

After creating the `VirtualGateway` in cluster1, let's see what is created in Istio.

```
❯ k get gateway -A                                                                 
NAMESPACE        NAME                                                              AGE
istio-gateways   virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738   139m

❯ k get gateway -n istio-gateways virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738 -oyaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  creationTimestamp: "2022-04-01T19:05:52Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: istio-gateways
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: VirtualGateway
    gloo.solo.io/parent_name: north-south-gw
    gloo.solo.io/parent_namespace: istio-gateways
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738
  namespace: istio-gateways
  resourceVersion: "333241"
  uid: 88ace23d-3ab9-4f1c-983b-eeb8ce328d1d
spec:
  selector:
    app: istio-ingressgateway
    istio: ingressgateway
  servers:
  - hosts:
    - '*'
    port:
      name: http-8080-all
      number: 8080
      protocol: HTTP
```

From this `Gateway` we can see the `parent_kind` value is `VirtualGateway` with the parent name of `north-south-gw`.  This gives us an easy way to trace Gloo Mesh translation.

It also may be a bit surprising not to see the `Gateway` configured for port 80.  However, if you look at the `istio-ingressgateway` service in the istio-gateways namespace, you can see that the `targetPort` for http is set to 8080.

Let's see how using these labels can help us find resources created by Gloo Mesh.

```
for crd in `kubectl get crd | grep istio | cut -f 1 -d ' '`; do 
    kubectl get ${crd} -l gloo.solo.io/parent_name=north-south-gw -n istio-gateways --ignore-not-found=true
done
NAME                                                              AGE
virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738   6h12m
```

For your convenience, you can use the script `find-translation`.  Just pass in the name and namespace of the translation you are looking for.

```
❯ ./workshops/gloo-mesh/2.x/scripts/find-translation.sh north-south-gw istio-gateways
Looking for Istio translation for  north-south-gw in istio-gateways
NAME                                                              AGE
virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738   6h12m
```

For the `RouteTable` let's use our handy script to find the corresponding translation.

```
❯ ./workshops/gloo-mesh/2.x/scripts/find-translation.sh productpage bookinfo-frontends
Looking for Istio translation for productpage in bookinfo-frontends

```

Wait a second!  No translation?  Hmm, we do see though that this `RouteTable` is being exported and is tied to our `VirtualGateway` definition in the `istio-gateways` namespace.  Could it be there?

```
❯ ./workshops/gloo-mesh/2.x/scripts/find-translation.sh productpage istio-gateways    
Looking for Istio translation for productpage in istio-gateways
NAME                                                          GATEWAYS                                                              HOSTS   AGE
routetable-productpage-bookinfo-frontends-cluster1-gateways   ["virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738"]   ["*"]   5m14s
```

There it is.  Tricky!  Let's take a look at what it looks like.

```
❯ k get virtualservice routetable-productpage-bookinfo-frontends-cluster1-gateways -n istio-gateways -oyaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  creationTimestamp: "2022-04-02T01:21:46Z"
  generation: 1
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
  resourceVersion: "380653"
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
        host: productpage.bookinfo-frontends.svc.cluster.local
        port:
          number: 9080
```

So, we can also see how resources are scoped to prevent them from leaking across workspaces here.  Notice the `exportTo` value of "**.**".  This prevents this configuration from being exposed to any other namespace.

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab7 - Create bookinfo workspace](./lab7.md) | [Next - Lab9 - Traffic policies](./lab9.md) :arrow_right: |

