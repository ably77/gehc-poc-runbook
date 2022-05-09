#!/bin/bash

cluster1_context="solo-poc-solcls2-user@solo-poc-solcls2"

kubectl apply -k ../cluster1/1.3.a-workspace-settings --context ${cluster1_context}

kubectl apply -k ../cluster1/2.1.d-routing-weighted-canary-reviews-v2 --context ${cluster1_context}