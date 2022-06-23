[Back to Table of Contents](./README.md) :blue_book:

## Lab15 - Expose an external service

`ExternalServices` should be equal to `ServiceEntries` in the Istio world.  Indeed, we do see a `ServiceEntry` defined as well as a `DestinationRule`.

```
❯ ./scripts/find-translation.sh httpbin httpbin               
Looking for Istio translation for httpbin in httpbin
Looking for objects of type serviceentries.networking.istio.io
NAME                                               HOSTS             LOCATION   RESOLUTION   AGE
externalservice-httpbin-httpbin-cluster1-httpbin   ["httpbin.org"]              DNS          28m
Looking for objects of type wasmplugins.extensions.istio.io
Looking for objects of type gateways.networking.istio.io
Looking for objects of type authorizationpolicies.security.istio.io
Looking for objects of type envoyfilters.networking.istio.io
Looking for objects of type peerauthentications.security.istio.io
Looking for objects of type workloadentries.networking.istio.io
Looking for objects of type workloadgroups.networking.istio.io
Looking for objects of type virtualservices.networking.istio.io
Looking for objects of type requestauthentications.security.istio.io
Looking for objects of type destinationrules.networking.istio.io
NAME                                                           HOST          AGE
externalservice-httpbin-httpbin-cluster1-httpbin-org-httpbin   httpbin.org   28m
Looking for objects of type sidecars.networking.istio.io
Looking for objects of type telemetries.telemetry.istio.io
Looking for objects of type istiooperators.install.istio.io
```

Let's examine the `ServiceEntry`.

```
❯ k get se -n httpbin externalservice-httpbin-httpbin-cluster1-httpbin  -oyaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  creationTimestamp: "2022-05-06T14:28:28Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: httpbin
    context.mesh.gloo.solo.io/workspace: httpbin
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: ExternalService
    gloo.solo.io/parent_name: httpbin
    gloo.solo.io/parent_namespace: httpbin
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: externalservice-httpbin-httpbin-cluster1-httpbin
  namespace: httpbin
  resourceVersion: "45912"
  uid: da519eb4-934e-4025-8797-c43da424a51c
spec:
  exportTo:
  - .
  hosts:
  - httpbin.org
  ports:
  - name: http
    number: 80
    protocol: HTTP
    targetPort: 80
  - name: https
    number: 443
    protocol: HTTPS
    targetPort: 443
  resolution: DNS
```

Pretty straightforward.  This is just a well-known DNS entry for an HTTP based service.  Now, let's look at the `DestinationRule`.

```
❯ k get dr -n httpbin externalservice-httpbin-httpbin-cluster1-httpbin-org-httpbin -o yaml             
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  creationTimestamp: "2022-05-06T14:28:28Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: httpbin
    context.mesh.gloo.solo.io/workspace: httpbin
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: ExternalService
    gloo.solo.io/parent_name: httpbin
    gloo.solo.io/parent_namespace: httpbin
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: externalservice-httpbin-httpbin-cluster1-httpbin-org-httpbin
  namespace: httpbin
  resourceVersion: "45917"
  uid: 1e0f4e67-8e8a-4468-8fba-4d79fdf2028b
spec:
  host: httpbin.org
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: SIMPLE
        sni: httpbin.org
```

The `DestinationRule` sets up simple TLS and the sni header.

Since the `RouteTable` will create a `VirtualService` we would expect to find this resource in the istio-gateways namespace.

```
❯ ./scripts/find-translation.sh httpbin istio-gateways
Looking for Istio translation for httpbin in istio-gateways
Looking for objects of type serviceentries.networking.istio.io
NAME                                                HOSTS             LOCATION   RESOLUTION   AGE
externalservice-httpbin-httpbin-cluster1-gateways   ["httpbin.org"]              DNS          67m
Looking for objects of type wasmplugins.extensions.istio.io
Looking for objects of type gateways.networking.istio.io
Looking for objects of type authorizationpolicies.security.istio.io
Looking for objects of type envoyfilters.networking.istio.io
Looking for objects of type peerauthentications.security.istio.io
Looking for objects of type workloadentries.networking.istio.io
Looking for objects of type workloadgroups.networking.istio.io
Looking for objects of type virtualservices.networking.istio.io
NAME                                           GATEWAYS                                                              HOSTS   AGE
routetable-httpbin-httpbin-cluster1-gateways   ["virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738"]   ["*"]   87s
Looking for objects of type requestauthentications.security.istio.io
Looking for objects of type destinationrules.networking.istio.io
NAME                                                            HOST          AGE
externalservice-httpbin-httpbin-cluster1-httpbin-org-gateways   httpbin.org   68m
Looking for objects of type sidecars.networking.istio.io
Looking for objects of type telemetries.telemetry.istio.io
Looking for objects of type istiooperators.install.istio.io
```

Now, we also find a `ServiceEntry` and `DestinationRule` here. Let's check each of these.

```
❯ k get se -n istio-gateways externalservice-httpbin-httpbin-cluster1-gateways -oyaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  creationTimestamp: "2022-05-06T14:28:28Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: istio-gateways
    context.mesh.gloo.solo.io/workspace: gateways
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: ExternalService
    gloo.solo.io/parent_name: httpbin
    gloo.solo.io/parent_namespace: httpbin
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: externalservice-httpbin-httpbin-cluster1-gateways
  namespace: istio-gateways
  resourceVersion: "45913"
  uid: 3bf86ebd-7349-40c4-9a35-ef000fefa683
spec:
  exportTo:
  - .
  hosts:
  - httpbin.org
  ports:
  - name: http
    number: 80
    protocol: HTTP
    targetPort: 80
  - name: https
    number: 443
    protocol: HTTPS
    targetPort: 443
  resolution: DNS

❯ k get vs -n istio-gateways routetable-httpbin-httpbin-cluster1-gateways -oyaml                                                 
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  creationTimestamp: "2022-05-06T15:35:12Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: istio-gateways
    context.mesh.gloo.solo.io/workspace: gateways
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: RouteTable
    gloo.solo.io/parent_name: httpbin
    gloo.solo.io/parent_namespace: httpbin
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: routetable-httpbin-httpbin-cluster1-gateways
  namespace: istio-gateways
  resourceVersion: "54970"
  uid: 07487909-03ab-453a-86fd-ce9dbc26e8a9
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
        exact: /get
    name: httpbin-httpbin
    route:
    - destination:
        host: httpbin.org
        port:
          number: 443

❯ k get dr -n istio-gateways externalservice-httpbin-httpbin-cluster1-httpbin-org-gateways -oyaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  creationTimestamp: "2022-05-06T14:28:28Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: istio-gateways
    context.mesh.gloo.solo.io/workspace: gateways
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: ExternalService
    gloo.solo.io/parent_name: httpbin
    gloo.solo.io/parent_namespace: httpbin
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: externalservice-httpbin-httpbin-cluster1-httpbin-org-gateways
  namespace: istio-gateways
  resourceVersion: "45915"
  uid: a2de2b91-238f-4d84-b779-5a766b2892af
spec:
  host: httpbin.org
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: SIMPLE
        sni: httpbin.org
```

Let's see if anything changes as we shift traffic to the internal service.

The `VirtualService` changes due to weighted destinations.

```
❯ k get vs -n istio-gateways routetable-httpbin-httpbin-cluster1-gateways -oyaml                 
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  creationTimestamp: "2022-05-06T15:35:12Z"
  generation: 2
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: istio-gateways
    context.mesh.gloo.solo.io/workspace: gateways
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: RouteTable
    gloo.solo.io/parent_name: httpbin
    gloo.solo.io/parent_namespace: httpbin
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: routetable-httpbin-httpbin-cluster1-gateways
  namespace: istio-gateways
  resourceVersion: "55863"
  uid: 07487909-03ab-453a-86fd-ce9dbc26e8a9
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
        exact: /get
    name: httpbin-httpbin
    route:
    - destination:
        host: httpbin.org
        port:
          number: 443
      weight: 50
    - destination:
        host: in-mesh.httpbin.svc.cluster.local
        port:
          number: 8000
      weight: 50
```

Completing the traffic shift again modifies the `VirtualService` but leaves the `ServiceEntry` and `DestinationRule` intact.

```
❯ k get vs -n istio-gateways routetable-httpbin-httpbin-cluster1-gateways -oyaml                 
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  creationTimestamp: "2022-05-06T15:35:12Z"
  generation: 3
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: istio-gateways
    context.mesh.gloo.solo.io/workspace: gateways
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: RouteTable
    gloo.solo.io/parent_name: httpbin
    gloo.solo.io/parent_namespace: httpbin
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: routetable-httpbin-httpbin-cluster1-gateways
  namespace: istio-gateways
  resourceVersion: "56232"
  uid: 07487909-03ab-453a-86fd-ce9dbc26e8a9
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
        exact: /get
    name: httpbin-httpbin
    route:
    - destination:
        host: in-mesh.httpbin.svc.cluster.local
        port:
          number: 8000
```

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab14 - Create the httpbin workspace](./lab14.md) | [Next - Lab16 - Deploy Keycloak](./lab16.md) :arrow_right: |