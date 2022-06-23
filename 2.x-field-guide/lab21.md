[Back to Table of Contents](./README.md) :blue_book:

## Lab21 - Use the web application firewall filter

We should see a change to our `EnvoyFilter` again for WAF.

```
❯ k get envoyfilter -n istio-gateways 8443-http-filter-io-solo-filter-d1bb01748a01231808bfb1c8f69a176 -oyaml                                                               
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  creationTimestamp: "2022-05-09T22:05:49Z"
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
  name: 8443-http-filter-io-solo-filter-d1bb01748a01231808bfb1c8f69a176
  namespace: istio-gateways
  resourceVersion: "348017"
  uid: b6fe83c8-88b6-4803-ac7e-261654a7b841
spec:
  configPatches:
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
        name: io.solo.filters.http.modsecurity
        typedConfig:
          '@type': type.googleapis.com/udpa.type.v1.TypedStruct
          typeUrl: envoy.config.filter.http.modsecurity.v2.ModSecurity
          value:
            disabled: true
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
            disabled: true
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
          io.solo.filters.http.modsecurity:
            '@type': type.googleapis.com/udpa.type.v1.TypedStruct
            typeUrl: envoy.config.filter.http.modsecurity.v2.ModSecurityPerRoute
            value:
              customInterventionMessage: Log4Shell malicious payload
              ruleSets:
              - ruleStr: "SecRuleEngine On\nSecRequestBodyAccess On\nSecRule REQUEST_LINE|ARGS|ARGS_NAMES|REQUEST_COOKIES|REQUEST_COOKIES_NAMES|REQUEST_BODY|REQUEST_HEADERS|XML:/*|XML://@*
                  \ \n  \"@rx \\${jndi:(?:ldaps?|iiop|dns|rmi)://\" \n  \"id:1000,phase:2,deny,status:403,log,msg:'Potential
                  Remote Command Execution: Log4j CVE-2021-44228'\"\n"
  workloadSelector:
    labels:
      app: istio-ingressgateway
      istio: ingressgateway
```

That's it for this edition of the field guide.  I hope you learned something and found it useful!


:arrow_left: [Previous - Lab20 - Apply rate limiting to the Gateway](./lab20.md) 
