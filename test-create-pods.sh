#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o pipefail

aws eks update-kubeconfig --name $CLUSTER_NAME

kubectl config set-context $(kubectl config current-context) --namespace=serverless

# use unique names for the test deployment and pod
test_deployment=test-deployment-run${GITHUB_RUN_NUMBER}
test_pod=tmp-shell-run${GITHUB_RUN_NUMBER}

kubectl create deployment $test_deployment --image=nginx:latest --replicas 3
kubectl run $test_pod --image amazonlinux:2018.03 -- sleep infinity

# wait for pods to become available 
kubectl wait --for condition=Available=True  deployment/$test_deployment --timeout 300s
kubectl wait --for=condition=Ready pod/$test_pod --timeout 300s

# grab the nginx pods and attempt to curl them
test_ips=($(kubectl get pods -l=app=$test_deployment -o jsonpath='{.items[*].status.podIP}'))
kubectl exec $test_pod -- curl $test_ips

# clean up
kubectl delete deployment $test_deployment
kubectl delete pod $test_pod