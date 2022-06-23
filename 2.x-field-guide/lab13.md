[Back to Table of Contents](./README.md) :blue_book:

## Lab13 - Zero Trust

Creating service isolation will create `PeerAuthentication` with STRICT mTLS mode.  But, the surprising part here is that the "gloo.solo.io/parent_name" we had been using for our lookups doesn't work in this case.  Instead, this setting needs to locate each service within the `Workspace` and assign them as the parent.  That way, as services come and go, so should the `PeerAuthentication` resources.

```
❯ k get peerauthentication -A                                                                          
NAMESPACE            NAME                                 MODE   AGE
bookinfo-backends    settings-reviews-9080-bookinfo              8m18s
bookinfo-backends    settings-details-9080-bookinfo              8m18s
bookinfo-backends    settings-ratings-9080-bookinfo              8m18s
bookinfo-frontends   settings-productpage-9080-bookinfo          8m18s
```

Let's look at the one for productpage.

```
❯ k get peerauthentication -n bookinfo-frontends settings-productpage-9080-bookinfo -o yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  creationTimestamp: "2022-04-02T23:02:59Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-frontends
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: ""
    gloo.solo.io/parent_kind: Service
    gloo.solo.io/parent_name: productpage
    gloo.solo.io/parent_namespace: bookinfo-frontends
    gloo.solo.io/parent_version: v1
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: settings-productpage-9080-bookinfo
  namespace: bookinfo-frontends
  resourceVersion: "546403"
  uid: 2e002e57-50b2-42c2-ab9a-e0412fdcd1f3
spec:
  portLevelMtls:
    "9080":
      mode: STRICT
  selector:
    matchLabels:
      app: productpage
```

In addition, reduced configuration can be achieved within the `Sidecar`.  Let's see what was created.

```
❯ k get sidecar -A                                                                         
NAMESPACE            NAME                                                          AGE
bookinfo-backends    sidecar-reviews-v2-bookinfo-backends-cluster1-bookinfo        13m
bookinfo-backends    sidecar-reviews-v1-bookinfo-backends-cluster1-bookinfo        13m
bookinfo-backends    sidecar-details-v1-bookinfo-backends-cluster1-bookinfo        13m
bookinfo-frontends   sidecar-productpage-v1-bookinfo-frontends-cluster1-bookinfo   13m
bookinfo-backends    sidecar-ratings-v1-bookinfo-backends-cluster1-bookinfo        13m
```

Again, we should inspect the resource created for productpage.

```
❯ k get sidecar -n bookinfo-frontends  sidecar-productpage-v1-bookinfo-frontends-cluster1-bookinfo -oyaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  creationTimestamp: "2022-04-02T23:02:59Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-frontends
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: apps
    gloo.solo.io/parent_kind: Deployment
    gloo.solo.io/parent_name: productpage-v1
    gloo.solo.io/parent_namespace: bookinfo-frontends
    gloo.solo.io/parent_version: v1
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: sidecar-productpage-v1-bookinfo-frontends-cluster1-bookinfo
  namespace: bookinfo-frontends
  resourceVersion: "546411"
  uid: f2eb558f-6d8a-42c2-976a-29d8dc793153
spec:
  egress:
  - hosts:
    - '*/details.bookinfo-backends.svc.cluster.local'
    - '*/productpage.bookinfo-frontends.svc.cluster.local'
    - '*/ratings.bookinfo-backends.svc.cluster.local'
    - '*/reviews.bookinfo-backends.svc.cluster.local'
  workloadSelector:
    labels:
      app: productpage
      version: v1
```

The egress hosts have been explicitly defined thus reducing configuration for the sidecar.  It also means that any external routing to a service not in the list will go to the **BlackHoleCluster**.

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab12 - Leverage Virtual Destinations](./lab12.md) | [Next - Lab14 - Create the httpbin workspace](./lab14.md) :arrow_right: |