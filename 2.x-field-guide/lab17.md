[Back to Table of Contents](./README.md) :blue_book:

## Lab17 - Securing the access with OAuth

You will notice that the `ExtAuthPolicy` is pulling the token from the jwt header and retrieving the email within scope.

The added label `oauth` will configure our `RouteTable` to use the extauth feature as we specified this label in the `ExtAuthPolicy`.

If we now inspect the routes for the ingress gateway, we should see our added /callback route.

```
❯ istioctl pc routes deploy/istio-ingressgateway -n istio-gateways
NAME                                                                                                         DOMAINS     MATCH                  VIRTUAL SERVICE
https.8443.https-8443-all.virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738.istio-gateways     *           /productpage           routetable-productpage-bookinfo-frontends-cluster1-gateways.istio-gateways
https.8443.https-8443-all.virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738.istio-gateways     *           /static*               routetable-productpage-bookinfo-frontends-cluster1-gateways.istio-gateways
https.8443.https-8443-all.virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738.istio-gateways     *           /login                 routetable-productpage-bookinfo-frontends-cluster1-gateways.istio-gateways
https.8443.https-8443-all.virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738.istio-gateways     *           /logout                routetable-productpage-bookinfo-frontends-cluster1-gateways.istio-gateways
https.8443.https-8443-all.virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738.istio-gateways     *           /api/v1/products*      routetable-productpage-bookinfo-frontends-cluster1-gateways.istio-gateways
https.8443.https-8443-all.virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738.istio-gateways     *           /get                   routetable-httpbin-httpbin-cluster1-gateways.istio-gateways
https.8443.https-8443-all.virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738.istio-gateways     *           /callback*             routetable-httpbin-httpbin-cluster1-gateways.istio-gateways
                                                                                                             *           /healthz/ready*
                                                                                                             *           /stats/prometheus*  
```

And, if we look at one of these in detail, we should see the extauth filter being used.

```
❯ istioctl pc routes istio-ingressgateway-86ddb84ff6-7mqns.istio-gateways --name https.443.https-443.virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738.istio-gateways -oyaml
- name: https.443.https-443.virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738.istio-gateways
  validateClusters: false
  virtualHosts:
  - domains:
    - '*'
    includeRequestAttemptCount: true
    name: '*:443'
    routes:
    - decorator:
        operation: productpage.bookinfo-frontends.svc.cluster.local:9080/productpage
      match:
        caseSensitive: true
        path: /productpage
      metadata:
        filterMetadata:
          istio:
            config: /apis/networking.istio.io/v1alpha3/namespaces/istio-gateways/virtual-service/routetable-productpage-bookinfo-frontends-cluster1-gateways
      name: productpage-productpage
      route:
        cluster: outbound|9080||productpage.bookinfo-frontends.svc.cluster.local
        maxGrpcTimeout: 0s
        retryPolicy:
          hostSelectionRetryMaxAttempts: "5"
          numRetries: 2
          retriableStatusCodes:
          - 503
          retryHostPredicate:
          - name: envoy.retry_host_predicates.previous_hosts
          retryOn: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
        timeout: 0s
      typedPerFilterConfig:
        envoy.filters.http.ext_authz:
          '@type': type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthzPerRoute
          checkSettings:
            contextExtensions:
              config_id: gloo-mesh-addons.productpage-bookinfo-frontends-cluster1-ext-auth-service
              source_name: route
              source_type: route
    - decorator:
        operation: productpage.bookinfo-frontends.svc.cluster.local:9080/static*
      match:
        caseSensitive: true
        prefix: /static
      metadata:
        filterMetadata:
          istio:
            config: /apis/networking.istio.io/v1alpha3/namespaces/istio-gateways/virtual-service/routetable-productpage-bookinfo-frontends-cluster1-gateways
      name: productpage-productpage
      route:
        cluster: outbound|9080||productpage.bookinfo-frontends.svc.cluster.local
        maxGrpcTimeout: 0s
        retryPolicy:
          hostSelectionRetryMaxAttempts: "5"
          numRetries: 2
          retriableStatusCodes:
          - 503
          retryHostPredicate:
          - name: envoy.retry_host_predicates.previous_hosts
          retryOn: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
        timeout: 0s
      typedPerFilterConfig:
        envoy.filters.http.ext_authz:
          '@type': type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthzPerRoute
          checkSettings:
            contextExtensions:
              config_id: gloo-mesh-addons.productpage-bookinfo-frontends-cluster1-ext-auth-service
              source_name: route
              source_type: route
    - decorator:
        operation: productpage.bookinfo-frontends.svc.cluster.local:9080/login
      match:
        caseSensitive: true
        path: /login
      metadata:
        filterMetadata:
          istio:
            config: /apis/networking.istio.io/v1alpha3/namespaces/istio-gateways/virtual-service/routetable-productpage-bookinfo-frontends-cluster1-gateways
      name: productpage-productpage
      route:
        cluster: outbound|9080||productpage.bookinfo-frontends.svc.cluster.local
        maxGrpcTimeout: 0s
        retryPolicy:
          hostSelectionRetryMaxAttempts: "5"
          numRetries: 2
          retriableStatusCodes:
          - 503
          retryHostPredicate:
          - name: envoy.retry_host_predicates.previous_hosts
          retryOn: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
        timeout: 0s
      typedPerFilterConfig:
        envoy.filters.http.ext_authz:
          '@type': type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthzPerRoute
          checkSettings:
            contextExtensions:
              config_id: gloo-mesh-addons.productpage-bookinfo-frontends-cluster1-ext-auth-service
              source_name: route
              source_type: route
    - decorator:
        operation: productpage.bookinfo-frontends.svc.cluster.local:9080/logout
      match:
        caseSensitive: true
        path: /logout
      metadata:
        filterMetadata:
          istio:
            config: /apis/networking.istio.io/v1alpha3/namespaces/istio-gateways/virtual-service/routetable-productpage-bookinfo-frontends-cluster1-gateways
      name: productpage-productpage
      route:
        cluster: outbound|9080||productpage.bookinfo-frontends.svc.cluster.local
        maxGrpcTimeout: 0s
        retryPolicy:
          hostSelectionRetryMaxAttempts: "5"
          numRetries: 2
          retriableStatusCodes:
          - 503
          retryHostPredicate:
          - name: envoy.retry_host_predicates.previous_hosts
          retryOn: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
        timeout: 0s
      typedPerFilterConfig:
        envoy.filters.http.ext_authz:
          '@type': type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthzPerRoute
          checkSettings:
            contextExtensions:
              config_id: gloo-mesh-addons.productpage-bookinfo-frontends-cluster1-ext-auth-service
              source_name: route
              source_type: route
    - decorator:
        operation: productpage.bookinfo-frontends.svc.cluster.local:9080/api/v1/products*
      match:
        caseSensitive: true
        prefix: /api/v1/products
      metadata:
        filterMetadata:
          istio:
            config: /apis/networking.istio.io/v1alpha3/namespaces/istio-gateways/virtual-service/routetable-productpage-bookinfo-frontends-cluster1-gateways
      name: productpage-productpage
      route:
        cluster: outbound|9080||productpage.bookinfo-frontends.svc.cluster.local
        maxGrpcTimeout: 0s
        retryPolicy:
          hostSelectionRetryMaxAttempts: "5"
          numRetries: 2
          retriableStatusCodes:
          - 503
          retryHostPredicate:
          - name: envoy.retry_host_predicates.previous_hosts
          retryOn: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
        timeout: 0s
      typedPerFilterConfig:
        envoy.filters.http.ext_authz:
          '@type': type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthzPerRoute
          checkSettings:
            contextExtensions:
              config_id: gloo-mesh-addons.productpage-bookinfo-frontends-cluster1-ext-auth-service
              source_name: route
              source_type: route
    - decorator:
        operation: productpage.bookinfo-frontends.svc.cluster.local:9080/callback*
      match:
        caseSensitive: true
        prefix: /callback
      metadata:
        filterMetadata:
          istio:
            config: /apis/networking.istio.io/v1alpha3/namespaces/istio-gateways/virtual-service/routetable-productpage-bookinfo-frontends-cluster1-gateways
      name: productpage-productpage
      route:
        cluster: outbound|9080||productpage.bookinfo-frontends.svc.cluster.local
        maxGrpcTimeout: 0s
        retryPolicy:
          hostSelectionRetryMaxAttempts: "5"
          numRetries: 2
          retriableStatusCodes:
          - 503
          retryHostPredicate:
          - name: envoy.retry_host_predicates.previous_hosts
          retryOn: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
        timeout: 0s
      typedPerFilterConfig:
        envoy.filters.http.ext_authz:
          '@type': type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthzPerRoute
          checkSettings:
            contextExtensions:
              config_id: gloo-mesh-addons.productpage-bookinfo-frontends-cluster1-ext-auth-service
              source_name: route
              source_type: route

```

If you want to see more details on what is happening with extauth you can edit the extauth deployment in *gloo-mesh-addons* namespace.  Find the `LOG_LEVEL` setting and change it from `INFO` to `DEBUG`.

We also notice a new filter being applied in the istio-gateways namespace.

```
❯ ./scripts/find-translation.sh httpbin istio-gateways
Looking for Istio translation for httpbin in istio-gateways
Looking for objects of type serviceentries.networking.istio.io
NAME                                                HOSTS             LOCATION   RESOLUTION   AGE
externalservice-httpbin-httpbin-cluster1-gateways   ["httpbin.org"]              DNS          4h19m
Looking for objects of type wasmplugins.extensions.istio.io
Looking for objects of type gateways.networking.istio.io
Looking for objects of type authorizationpolicies.security.istio.io
Looking for objects of type envoyfilters.networking.istio.io
NAME                                                              AGE
8443-http-filter-envoy-filters--79df6b45eef7ba7214287e02190ca5d   7m24s
Looking for objects of type peerauthentications.security.istio.io
Looking for objects of type workloadentries.networking.istio.io
Looking for objects of type workloadgroups.networking.istio.io
Looking for objects of type virtualservices.networking.istio.io
NAME                                           GATEWAYS                                                              HOSTS   AGE
routetable-httpbin-httpbin-cluster1-gateways   ["virtualgateway-north-south-gw-i-854116bec1b325afa7cdbcac4c80738"]   ["*"]   3d5h
Looking for objects of type requestauthentications.security.istio.io
Looking for objects of type destinationrules.networking.istio.io
NAME                                                            HOST          AGE
externalservice-httpbin-httpbin-cluster1-httpbin-org-gateways   httpbin.org   4h20m
Looking for objects of type sidecars.networking.istio.io
Looking for objects of type telemetries.telemetry.istio.io
Looking for objects of type istiooperators.install.istio.io
```

This filter allows us to patch the gateway to configure external auth for the httpbin app.

```
❯ k get envoyfilter 8443-http-filter-envoy-filters--79df6b45eef7ba7214287e02190ca5d -n istio-gateways -oyaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  creationTimestamp: "2022-05-09T20:41:18Z"
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
  name: 8443-http-filter-envoy-filters--79df6b45eef7ba7214287e02190ca5d
  namespace: istio-gateways
  resourceVersion: "336572"
  uid: ea8a9964-0796-4392-86ef-ae6b654e01a2
spec:
  configPatches:
  - applyTo: HTTP_ROUTE
    match:
      context: GATEWAY
      routeConfiguration:
        vhost:
          route:
            name: httpbin-httpbin
    patch:
      operation: MERGE
      value:
        typedPerFilterConfig:
          envoy.filters.http.ext_authz:
            '@type': type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthzPerRoute
            checkSettings:
              contextExtensions:
                config_id: gloo-mesh-addons.httpbin-httpbin-cluster1-ext-auth-service
                source_name: route
                source_type: route
  - applyTo: HTTP_FILTER
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
            subFilter:
              name: envoy.filters.http.router
        portNumber: 8443
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.filters.http.ext_authz
        typedConfig:
          '@type': type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
          grpcService:
            envoyGrpc:
              authority: outbound_.8083_._.ext-auth-service.gloo-mesh-addons.svc.cluster.local
              clusterName: outbound|8083||ext-auth-service.gloo-mesh-addons.svc.cluster.local
            timeout: 2s
          metadataContextNamespaces:
          - envoy.filters.http.jwt_authn
          transportApiVersion: V3
  workloadSelector:
    labels:
      app: istio-ingressgateway
      istio: ingressgateway
```

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab16 - Deploy Keycloak](./lab16.md) | [Next - Lab18 - Use the JWT filter to create headers from claims](./lab18.md) :arrow_right: |
