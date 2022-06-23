[Back to Table of Contents](./README.md) :blue_book:

## Lab11 - Multi-cluster Traffic

Remember that when we initially created our `Workspace` resource for bookinfo-frontends, we did not specify any options.  Here, we are going to ensure federation across clusters in the `Workspace` specifically for the reviews app. The reviews app lives in our bookinfo-backends namespace, so let's use that to see what translations were created in Istio.

```
❯ ./scripts/find-translation.sh reviews bookinfo-backends                                                  
Looking for Istio translation for reviews in bookinfo-backends
Looking for objects of type requestauthentications.security.istio.io
Looking for objects of type wasmplugins.extensions.istio.io
Looking for objects of type workloadgroups.networking.istio.io
Looking for objects of type telemetries.telemetry.istio.io
Looking for objects of type gateways.networking.istio.io
Looking for objects of type workloadentries.networking.istio.io
Looking for objects of type virtualservices.networking.istio.io
Looking for objects of type envoyfilters.networking.istio.io
Looking for objects of type serviceentries.networking.istio.io
NAME                                                        HOSTS                                               LOCATION        RESOLUTION   AGE
vd-reviews-bookinfo-backends-svc-cluster2-global-bookinfo   ["reviews.bookinfo-backends.svc.cluster2.global"]   MESH_INTERNAL   STATIC       27m
vd-reviews-bookinfo-backends-svc-cluster1-global-bookinfo   ["reviews.bookinfo-backends.svc.cluster1.global"]   MESH_INTERNAL   STATIC       27m
Looking for objects of type peerauthentications.security.istio.io
Looking for objects of type sidecars.networking.istio.io
Looking for objects of type destinationrules.networking.istio.io
NAME                                                              HOST                                            AGE
reviews-bookinfo-backends-svc-c-bd30347304724f479d9c85501f32102   reviews.bookinfo-backends.svc.cluster2.global   27m
reviews-bookinfo-backends-svc-c-0f390762f392ff70f338c84fafb6f2f   reviews.bookinfo-backends.svc.cluster1.global   27m
Looking for objects of type authorizationpolicies.security.istio.io
Looking for objects of type istiooperators.install.istio.io
```

We see two new `ServiceEntries` with the prefix "vd-".  This indicates a virtual destination spanning clusters.  Likewise, we see two new `DestinationRules` were created.  Let's take a look at the `ServiceEntries` first.

```
❯ k get serviceentry -n bookinfo-backends vd-reviews-bookinfo-backends-svc-cluster1-global-bookinfo -oyaml                                              
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  creationTimestamp: "2022-05-03T13:05:29Z"
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
  name: vd-reviews-bookinfo-backends-svc-cluster1-global-bookinfo
  namespace: bookinfo-backends
  resourceVersion: "726612"
  uid: 2f87b3bf-12d4-40c2-becf-4bbe2385bcfb
spec:
  addresses:
  - 244.154.203.238
  exportTo:
  - bookinfo-backends
  - bookinfo-frontends
  - gloo-mesh-addons
  - istio-gateways
  hosts:
  - reviews.bookinfo-backends.svc.cluster1.global
  location: MESH_INTERNAL
  ports:
  - name: http-9080
    number: 9080
    protocol: HTTP
    targetPort: 9080
  resolution: STATIC
  workloadSelector:
    labels:
      app: reviews

❯ k get serviceentry -n bookinfo-backends vd-reviews-bookinfo-backends-svc-cluster2-global-bookinfo -oyaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  creationTimestamp: "2022-05-03T13:05:29Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-backends
    gloo.solo.io/parent_cluster: cluster2
    gloo.solo.io/parent_group: ""
    gloo.solo.io/parent_kind: Service
    gloo.solo.io/parent_name: reviews
    gloo.solo.io/parent_namespace: bookinfo-backends
    gloo.solo.io/parent_version: v1
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: vd-reviews-bookinfo-backends-svc-cluster2-global-bookinfo
  namespace: bookinfo-backends
  resourceVersion: "726609"
  uid: 2a75e9eb-b4b1-427c-be40-d01086088099
spec:
  addresses:
  - 243.225.175.152
  endpoints:
  - address: 172.23.0.6
    labels:
      app: reviews
    locality: us-east-1
    ports:
      http-9080: 15443
  exportTo:
  - .
  hosts:
  - reviews.bookinfo-backends.svc.cluster2.global
  location: MESH_INTERNAL
  ports:
  - name: http-9080
    number: 9080
    protocol: HTTP
  resolution: STATIC
```

You will notice that the `ServiceEntry` intended for multicluster routing only exports its configuration to the current namespace while the `ServiceEntry` for the same cluster exports its configuration to both the bookinfo and gateways `Workspaces`.  Since this application is only routable within the `Workspace` and does not allow direct ingress, this makes sense.  You can also see that for the multicluster `ServiceEntry` the east-west address and port are specified along with the locality.  Additionally, we set resolution to STATIC to take advantage of Istio's ability to map static addresses to discovery.

You should also see the `.global` `ServiceEntry` in the bookinfo-frontends namespace.

```
❯ ./scripts/find-translation.sh reviews bookinfo-frontends
Looking for Istio translation for reviews in bookinfo-frontends
Looking for objects of type requestauthentications.security.istio.io
Looking for objects of type wasmplugins.extensions.istio.io
Looking for objects of type workloadgroups.networking.istio.io
Looking for objects of type telemetries.telemetry.istio.io
Looking for objects of type gateways.networking.istio.io
Looking for objects of type workloadentries.networking.istio.io
Looking for objects of type virtualservices.networking.istio.io
Looking for objects of type envoyfilters.networking.istio.io
Looking for objects of type serviceentries.networking.istio.io
NAME                                                        HOSTS                                               LOCATION        RESOLUTION   AGE
vd-reviews-bookinfo-backends-svc-cluster2-global-bookinfo   ["reviews.bookinfo-backends.svc.cluster2.global"]   MESH_INTERNAL   STATIC       20m
Looking for objects of type peerauthentications.security.istio.io
Looking for objects of type sidecars.networking.istio.io
Looking for objects of type destinationrules.networking.istio.io
NAME                                                              HOST                                            AGE
reviews-bookinfo-backends-svc-c-f125a93fe5abd92c0960021df95a990   reviews.bookinfo-backends.svc.cluster2.global   21m
Looking for objects of type authorizationpolicies.security.istio.io
Looking for objects of type istiooperators.install.istio.io
```

Let's take a look at both the `Service Entry` and the `Destination Rule`.

```
❯ k get serviceentry -n bookinfo-frontends vd-reviews-bookinfo-backends-svc-cluster2-global-bookinfo -oyaml                              
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  creationTimestamp: "2022-05-03T13:05:29Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-frontends
    gloo.solo.io/parent_cluster: cluster2
    gloo.solo.io/parent_group: ""
    gloo.solo.io/parent_kind: Service
    gloo.solo.io/parent_name: reviews
    gloo.solo.io/parent_namespace: bookinfo-backends
    gloo.solo.io/parent_version: v1
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: vd-reviews-bookinfo-backends-svc-cluster2-global-bookinfo
  namespace: bookinfo-frontends
  resourceVersion: "726611"
  uid: 9257961f-9138-45a6-b676-baee0015ef98
spec:
  addresses:
  - 249.147.222.125
  endpoints:
  - address: 172.23.0.6
    labels:
      app: reviews
    locality: us-east-1
    ports:
      http-9080: 15443
  exportTo:
  - .
  hosts:
  - reviews.bookinfo-backends.svc.cluster2.global
  location: MESH_INTERNAL
  ports:
  - name: http-9080
    number: 9080
    protocol: HTTP
  resolution: STATIC

❯ k get dr -n bookinfo-frontends reviews-bookinfo-backends-svc-c-f125a93fe5abd92c0960021df95a990 -oyaml                                                               
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  creationTimestamp: "2022-05-03T13:05:29Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-frontends
    gloo.solo.io/parent_cluster: cluster2
    gloo.solo.io/parent_group: ""
    gloo.solo.io/parent_kind: Service
    gloo.solo.io/parent_name: reviews
    gloo.solo.io/parent_namespace: bookinfo-backends
    gloo.solo.io/parent_version: v1
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: reviews-bookinfo-backends-svc-c-f125a93fe5abd92c0960021df95a990
  namespace: bookinfo-frontends
  resourceVersion: "726606"
  uid: cc105056-bd42-4f09-bffb-57473f7f13a0
spec:
  exportTo:
  - .
  host: reviews.bookinfo-backends.svc.cluster2.global
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 9080
      tls:
        mode: ISTIO_MUTUAL
        subjectAltNames:
        - spiffe://cluster1/ns/bookinfo-backends/sa/bookinfo-reviews
        - spiffe://cluster2/ns/bookinfo-backends/sa/bookinfo-reviews
```

Let's now look at the `DestinationRules` for the resources in bookinfo-backends.

```
❯ k get dr -n bookinfo-backends reviews-bookinfo-backends-clust-987b390291822a7002061e754fed12e -oyaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  creationTimestamp: "2022-04-02T12:00:40Z"
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
  name: reviews-bookinfo-backends-clust-987b390291822a7002061e754fed12e
  namespace: bookinfo-backends
  resourceVersion: "462090"
  uid: 09641601-78a4-47e3-9dca-fa44685262e9
spec:
  exportTo:
  - bookinfo-backends
  - bookinfo-frontends
  - gloo-mesh-addons
  - istio-gateways
  host: reviews.bookinfo-backends.cluster1
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 9080
      tls:
        mode: ISTIO_MUTUAL
        subjectAltNames:
        - spiffe://cluster1/ns/bookinfo-backends/sa/bookinfo-reviews
        - spiffe://cluster2/ns/bookinfo-backends/sa/bookinfo-reviews

❯ k get dr -n bookinfo-backends reviews-bookinfo-backends-clust-a165ada6b642cfe2d2fbfe103cc7bc3 -oyaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  creationTimestamp: "2022-04-02T12:00:40Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-backends
    gloo.solo.io/parent_cluster: cluster2
    gloo.solo.io/parent_group: ""
    gloo.solo.io/parent_kind: Service
    gloo.solo.io/parent_name: reviews
    gloo.solo.io/parent_namespace: bookinfo-backends
    gloo.solo.io/parent_version: v1
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: reviews-bookinfo-backends-clust-a165ada6b642cfe2d2fbfe103cc7bc3
  namespace: bookinfo-backends
  resourceVersion: "462091"
  uid: 3541ba9b-5ef9-4ad6-8100-1e264982c22f
spec:
  exportTo:
  - .
  host: reviews.bookinfo-backends.cluster2
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 9080
      tls:
        mode: ISTIO_MUTUAL
        subjectAltNames:
        - spiffe://cluster1/ns/bookinfo-backends/sa/bookinfo-reviews
        - spiffe://cluster2/ns/bookinfo-backends/sa/bookinfo-reviews
```

We can also use **istioctl** to investigate the clusters configured in the bookinfo project.  First, let's find the proxy name for productpage.

```
❯ istioctl ps                                                                         
NAME                                                      CLUSTER     CDS        LDS        EDS        RDS          ISTIOD                           VERSION
details-v1-79f774bdb9-k4dmb.bookinfo-backends                         SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
ext-auth-service-79bd844fb9-h8hv7.gloo-mesh-addons                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
in-mesh-5d5b9fdbcb-8rs59.httpbin                                      SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
istio-eastwestgateway-6c4fdf6bf7-kmfd7.istio-gateways                 SYNCED     SYNCED     SYNCED     NOT SENT     istiod-1-11-7bc7447755-vgp6n     1.11.7
istio-ingressgateway-86ddb84ff6-7mqns.istio-gateways                  SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
productpage-v1-5c87b6dcf6-pz8rn.bookinfo-frontends                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
rate-limiter-8488bc4f87-sh77d.gloo-mesh-addons                        SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
ratings-v1-b6994bb9-4hp22.bookinfo-backends                           SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
redis-5c8dc9fb44-kjbwg.gloo-mesh-addons                               SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
reviews-v1-545db77b95-9xm97.bookinfo-backends                         SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
reviews-v2-7bf8c9648f-fm9j6.bookinfo-backends                         SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
svclb-istio-eastwestgateway-lvnqr.istio-gateways                      SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7
svclb-istio-ingressgateway-rkjjn.istio-gateways                       SYNCED     SYNCED     SYNCED     SYNCED       istiod-1-11-7bc7447755-vgp6n     1.11.7

❯ istioctl pc clusters productpage-v1-5c87b6dcf6-pz8rn.bookinfo-frontends | grep reviews
reviews.bookinfo-backends.cluster1                         9080      -          outbound      EDS              reviews-bookinfo-backends-clust-987b390291822a7002061e754fed12e.bookinfo-backends
reviews.bookinfo-backends.cluster2                         9080      -          outbound      EDS              reviews-bookinfo-backends-clust-fc22a0f4b7ed6dab55e7beba2df5dc8.bookinfo-frontends
reviews.bookinfo-backends.svc.cluster.local                9080      -          outbound      EDS 
```

We can see how the cluster is configured.  Let's look at reviews.bookinfo-backends.cluster1.

```
❯ istioctl pc clusters productpage-v1-69f8699b74-j7rxj.bookinfo-frontends --fqdn reviews.bookinfo-backends.svc.cluster1.global -o json
[
    {
        "name": "outbound|9080||reviews.bookinfo-backends.svc.cluster1.global",
        "type": "EDS",
        "edsClusterConfig": {
            "edsConfig": {
                "ads": {},
                "initialFetchTimeout": "0s",
                "resourceApiVersion": "V3"
            },
            "serviceName": "outbound|9080||reviews.bookinfo-backends.svc.cluster1.global"
        },
        "connectTimeout": "10s",
        "circuitBreakers": {
            "thresholds": [
                {
                    "maxConnections": 4294967295,
                    "maxPendingRequests": 4294967295,
                    "maxRequests": 4294967295,
                    "maxRetries": 4294967295,
                    "trackRemaining": true
                }
            ]
        },
        "commonLbConfig": {
            "localityWeightedLbConfig": {}
        },
        "transportSocket": {
            "name": "envoy.transport_sockets.tls",
            "typedConfig": {
                "@type": "type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext",
                "commonTlsContext": {
                    "tlsCertificateSdsSecretConfigs": [
                        {
                            "name": "default",
                            "sdsConfig": {
                                "apiConfigSource": {
                                    "apiType": "GRPC",
                                    "transportApiVersion": "V3",
                                    "grpcServices": [
                                        {
                                            "envoyGrpc": {
                                                "clusterName": "sds-grpc"
                                            }
                                        }
                                    ],
                                    "setNodeOnFirstMessageOnly": true
                                },
                                "initialFetchTimeout": "0s",
                                "resourceApiVersion": "V3"
                            }
                        }
                    ],
                    "combinedValidationContext": {
                        "defaultValidationContext": {
                            "matchSubjectAltNames": [
                                {
                                    "exact": "spiffe://cluster1/ns/bookinfo-backends/sa/bookinfo-reviews"
                                },
                                {
                                    "exact": "spiffe://cluster2/ns/bookinfo-backends/sa/bookinfo-reviews"
                                }
                            ]
                        },
                        "validationContextSdsSecretConfig": {
                            "name": "ROOTCA",
                            "sdsConfig": {
                                "apiConfigSource": {
                                    "apiType": "GRPC",
                                    "transportApiVersion": "V3",
                                    "grpcServices": [
                                        {
                                            "envoyGrpc": {
                                                "clusterName": "sds-grpc"
                                            }
                                        }
                                    ],
                                    "setNodeOnFirstMessageOnly": true
                                },
                                "initialFetchTimeout": "0s",
                                "resourceApiVersion": "V3"
                            }
                        }
                    },
                    "alpnProtocols": [
                        "istio-peer-exchange",
                        "istio"
                    ]
                },
                "sni": "outbound_.9080_._.reviews.bookinfo-backends.svc.cluster1.global"
            }
        },
        "metadata": {
            "filterMetadata": {
                "istio": {
                    "config": "/apis/networking.istio.io/v1alpha3/namespaces/bookinfo-backends/destination-rule/reviews-bookinfo-backends-svc-c-0f390762f392ff70f338c84fafb6f2f",
                    "default_original_port": 9080,
                    "services": [
                        {
                            "host": "reviews.bookinfo-backends.svc.cluster1.global",
                            "name": "reviews.bookinfo-backends.svc.cluster1.global",
                            "namespace": "bookinfo-backends"
                        }
                    ]
                }
            }
        },
        "filters": [
            {
                "name": "istio.metadata_exchange",
                "typedConfig": {
                    "@type": "type.googleapis.com/envoy.tcp.metadataexchange.config.MetadataExchange",
                    "protocol": "istio-peer-exchange"
                }
            }
        ]
    }
]
```

Quite a lot of configuration has happened simply by adding federation for a single service.  Now, let's add the `RouteTable` which will setup subset routing.  If we use our handy tool to check translations, we can see one new `VirtualService` and a new `DestinationRule` were created on cluster1.

```
❯ ./workshops/gloo-mesh/2.x/scripts/find-translation.sh reviews bookinfo-backends
Looking for Istio translation for reviews in bookinfo-backends
Looking for objects of type authorizationpolicies.security.istio.io
Looking for objects of type workloadentries.networking.istio.io
Looking for objects of type envoyfilters.networking.istio.io
Looking for objects of type sidecars.networking.istio.io
Looking for objects of type serviceentries.networking.istio.io
NAME                                             HOSTS                                    LOCATION        RESOLUTION   AGE
vd-reviews-bookinfo-backends-cluster1-bookinfo   ["reviews.bookinfo-backends.cluster1"]   MESH_INTERNAL   STATIC       167m
vd-reviews-bookinfo-backends-cluster2-bookinfo   ["reviews.bookinfo-backends.cluster2"]   MESH_INTERNAL   STATIC       167m
Looking for objects of type requestauthentications.security.istio.io
Looking for objects of type virtualservices.networking.istio.io
NAME                                                     GATEWAYS   HOSTS                                             AGE
routetable-reviews-bookinfo-backends-cluster1-bookinfo   ["mesh"]   ["reviews.bookinfo-backends.svc.cluster.local"]   4m59s
Looking for objects of type destinationrules.networking.istio.io
NAME                                                              HOST                                 AGE
reviews-bookinfo-backends-clust-987b390291822a7002061e754fed12e   reviews.bookinfo-backends.cluster1   167m
reviews-bookinfo-backends-clust-a165ada6b642cfe2d2fbfe103cc7bc3   reviews.bookinfo-backends.cluster2   167m
reviews-bookinfo-backends-clust-5144d70802ee60e8bbc93b58242bc18   reviews.bookinfo-backends.cluster2   5m1s
Looking for objects of type gateways.networking.istio.io
Looking for objects of type telemetries.telemetry.istio.io
Looking for objects of type peerauthentications.security.istio.io
Looking for objects of type workloadgroups.networking.istio.io
Looking for objects of type istiooperators.install.istio.io
```

Let's look at the `VirtualService`.

```
❯ k get virtualservice -n bookinfo-backends routetable-reviews-bookinfo-backends-cluster1-bookinfo -o yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  creationTimestamp: "2022-05-03T13:40:39Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-backends
    gloo.solo.io/parent_cluster: cluster1
    gloo.solo.io/parent_group: networking.gloo.solo.io
    gloo.solo.io/parent_kind: RouteTable
    gloo.solo.io/parent_name: reviews
    gloo.solo.io/parent_namespace: bookinfo-backends
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: routetable-reviews-bookinfo-backends-cluster1-bookinfo
  namespace: bookinfo-backends
  resourceVersion: "731557"
  uid: baceea41-f42e-4b76-863f-a350432c6bcd
spec:
  exportTo:
  - .
  gateways:
  - mesh
  hosts:
  - reviews.bookinfo-backends.svc.cluster.local
  http:
  - match:
    - sourceLabels:
        app: productpage
      uri:
        prefix: /
    name: reviews-reviews
    route:
    - destination:
        host: reviews.bookinfo-backends.svc.cluster2.global
        port:
          number: 9080
        subset: version-v3
```

The only significant difference between this `VirtualService` and the previous one is the addition of subset routing.  We should expect the same for the new `DestinationRule`.

```
❯ k get dr -n bookinfo-backends reviews-bookinfo-backends-svc-c-261e481ef4c5abe660451fb58eddaa9 -oyaml                                                                
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  creationTimestamp: "2022-05-03T13:40:39Z"
  generation: 1
  labels:
    agent.gloo.solo.io: gloo-mesh
    cluster.multicluster.solo.io: ""
    context.mesh.gloo.solo.io/cluster: cluster1
    context.mesh.gloo.solo.io/namespace: bookinfo-backends
    gloo.solo.io/parent_cluster: cluster2
    gloo.solo.io/parent_group: ""
    gloo.solo.io/parent_kind: Service
    gloo.solo.io/parent_name: reviews
    gloo.solo.io/parent_namespace: bookinfo-backends
    gloo.solo.io/parent_version: v1
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: reviews-bookinfo-backends-svc-c-261e481ef4c5abe660451fb58eddaa9
  namespace: bookinfo-backends
  resourceVersion: "731560"
  uid: 28252b41-9237-4a85-9664-1a4e23798e4e
spec:
  exportTo:
  - .
  host: reviews.bookinfo-backends.svc.cluster2.global
  subsets:
  - labels:
      version: v3
    name: version-v3
```

We should also see a new cluster added in Istio to handle routing to subset version-v3.

```
❯ istioctl pc clusters productpage-v1-69f8699b74-j7rxj.bookinfo-frontends | grep reviews                                              
reviews.bookinfo-backends.svc.cluster.local                9080      -              outbound      EDS              
reviews.bookinfo-backends.svc.cluster1.global              9080      -              outbound      EDS              reviews-bookinfo-backends-svc-c-0f390762f392ff70f338c84fafb6f2f.bookinfo-backends
reviews.bookinfo-backends.svc.cluster2.global              9080      -              outbound      EDS              reviews-bookinfo-backends-svc-c-f125a93fe5abd92c0960021df95a990.bookinfo-frontends
reviews.bookinfo-backends.svc.cluster2.global              9080      version-v3     outbound      EDS              reviews-bookinfo-backends-svc-c-f125a93fe5abd92c0960021df95a990.bookinfo-frontends        
```
| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab10 - Create the Root Trust Policy](./lab10.md) | [Next - Lab12 - Leverage Virtual Destinations](./lab12.md)  :arrow_right: | 

