[Back to Table of Contents](./README.md) :blue_book:

## Lab19 - Use the tranformation filter to manipulate headers

We should now see the `TransformationPolicy` applied to our `EnvoyFilter` in the istio-gateways namespace.

```
❯ k get envoyfilter -n istio-gateways 8443-http-filter-envoy-filters--0d8f69a489c623b96447e007896caee -oyaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  creationTimestamp: "2022-05-09T21:33:24Z"
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
  name: 8443-http-filter-envoy-filters--0d8f69a489c623b96447e007896caee
  namespace: istio-gateways
  resourceVersion: "343617"
  uid: 55c3eb83-7788-4a8c-bb35-4a1774d103b7
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
          io.solo.transformation:
            '@type': type.googleapis.com/udpa.type.v1.TypedStruct
            typeUrl: envoy.api.v2.filter.http.RouteTransformations
            value:
              transformations:
              - requestMatch:
                  requestTransformation:
                    transformationTemplate:
                      extractors:
                        organization:
                          header: X-Email
                          regex: .*@(.*)$
                          subgroup: 1
                      headers:
                        x-organization:
                          text: '{{ organization }}'
                stage: 1
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
        name: io.solo.transformation
        typedConfig:
          '@type': type.googleapis.com/udpa.type.v1.TypedStruct
          typeUrl: envoy.api.v2.filter.http.FilterTransformations
          value:
            stage: 1
  workloadSelector:
    labels:
      app: istio-ingressgateway
      istio: ingressgateway
```

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab 18 - Use the JWT filter to create headers from claims](./lab18.md) | [Next - Lab 20 - Apply rate limiting to the Gateway](./lab20.md) :arrow_right: |

