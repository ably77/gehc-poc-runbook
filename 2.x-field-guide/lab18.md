[Back to Table of Contents](./README.md) :blue_book:

## Lab18 - Use the JWT filter to create headers from claims

Our new JWTPolicy should have modified the EnvoyFilter for httpbin.

```
❯ k get envoyfilter 8443-http-filter-envoy-filters--3fee2299d5bb89d6b0dd0abe940d50d -n istio-gateways -o yaml                                                              
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  creationTimestamp: "2022-05-09T21:01:26Z"
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
  name: 8443-http-filter-envoy-filters--3fee2299d5bb89d6b0dd0abe940d50d
  namespace: istio-gateways
  resourceVersion: "339291"
  uid: e65142c2-1f34-47f6-ae59-3981a2e2fc5a
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
          io.solo.filters.http.solo_jwt_authn_staged:
            '@type': type.googleapis.com/udpa.type.v1.TypedStruct
            typeUrl: envoy.config.filter.http.solo_jwt_authn.v2.StagedJwtAuthnPerRoute
            value:
              jwtConfigs:
                "1":
                  claimsToHeaders:
                    principal:
                      claims:
                      - claim: email
                        header: X-Email
                  clearRouteCache: true
                  requirement: solo-mapping-key
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
        name: io.solo.filters.http.solo_jwt_authn_staged
        typedConfig:
          '@type': type.googleapis.com/udpa.type.v1.TypedStruct
          typeUrl: envoy.config.filter.http.solo_jwt_authn.v2.JwtWithStage
          value:
            jwtAuthn:
              filterStateRules:
                name: solo-filter-rules
                requires:
                  solo-mapping-key:
                    providerName: keycloak
              providers:
                keycloak:
                  fromHeaders:
                  - name: jwt
                  issuer: http://192.168.1.12:18080/auth/realms/master
                  payloadInMetadata: principal
                  remoteJwks:
                    httpUri:
                      cluster: outbound|18080||keycloak
                      timeout: 5s
                      uri: http://192.168.1.12:18080/auth/realms/master/protocol/openid-connect/certs
            stage: 1
  workloadSelector:
    labels:
      app: istio-ingressgateway
      istio: ingressgateway
```

While the `ExternalEndpoint` and `ExternalService` are new as well.

```
❯ ./scripts/find-translation.sh keycloak istio-gateways                                              
Looking for Istio translation for keycloak in istio-gateways
Looking for objects of type serviceentries.networking.istio.io
NAME                                                 HOSTS          LOCATION   RESOLUTION   AGE
externalservice-keycloak-httpbin-cluster1-gateways   ["keycloak"]              STATIC       8m9s
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
Looking for objects of type sidecars.networking.istio.io
Looking for objects of type telemetries.telemetry.istio.io
Looking for objects of type istiooperators.install.istio.io

❯ k get serviceentry -n istio-gateways externalservice-keycloak-httpbin-cluster1-gateways -oyaml             
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  creationTimestamp: "2022-05-09T21:01:26Z"
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
    gloo.solo.io/parent_name: keycloak
    gloo.solo.io/parent_namespace: httpbin
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: externalservice-keycloak-httpbin-cluster1-gateways
  namespace: istio-gateways
  resourceVersion: "339294"
  uid: a94750fd-5112-4a19-a779-fef29b0a54f8
spec:
  endpoints:
  - address: 192.168.1.12
    labels:
      expose: "true"
      host: keycloak
    ports:
      http: 18080
  exportTo:
  - .
  hosts:
  - keycloak
  ports:
  - name: http
    number: 18080
    protocol: HTTP
  resolution: STATIC
```

You should also see a `ServiceEntry` in the httpbin namespace.

```
❯ k get serviceentry -n httpbin externalservice-keycloak-httpbin-cluster1-httpbin -oyaml        
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  creationTimestamp: "2022-05-09T21:01:26Z"
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
    gloo.solo.io/parent_name: keycloak
    gloo.solo.io/parent_namespace: httpbin
    gloo.solo.io/parent_version: v2
    owner.gloo.solo.io/name: gloo-mesh
    reconciler.mesh.gloo.solo.io/name: translator
    relay.solo.io/cluster: cluster1
  name: externalservice-keycloak-httpbin-cluster1-httpbin
  namespace: httpbin
  resourceVersion: "339293"
  uid: a2b3e1d6-ef35-41f1-b9e5-635b01d7f9b7
spec:
  endpoints:
  - address: 192.168.1.12
    labels:
      expose: "true"
      host: keycloak
    ports:
      http: 18080
  exportTo:
  - .
  hosts:
  - keycloak
  ports:
  - name: http
    number: 18080
    protocol: HTTP
  resolution: STATIC
```
| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab 17 - Securing the access with OAuth](./lab17.md) | [Next - Lab 19 - Use the transformation filter to manipulate headers](./lab19.md) :arrow_right: |

