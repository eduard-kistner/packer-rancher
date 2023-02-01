#!/usr/bin/env bash
set -e

DOMAIN="${1}"

echo "Wait until rancher is up and ready"
while true; do
  sleep 10
  ### Getting rancher inside the loop is needed, as it could not be up yet
  RANCHER_POD=$(kubectl -n cattle-system get pods -l app=rancher | grep '1/1' | head -1 | awk '{ print $1 }')
  kubectl -n cattle-system exec ${RANCHER_POD} -- curl -sLk https://127.0.0.1/ping && break
  echo "Rancher is not up"
done

### set hostname for rancher
kubectl patch -n cattle-system ing/rancher --type=json -p='[{"op": "replace", "path": "/spec/rules/0/host", "value":"dash.'${DOMAIN}'"}]'
kubectl patch -n cattle-system ing/rancher --type=json -p='[{"op": "replace", "path": "/spec/tls/0/hosts/0", "value":"dash.'${DOMAIN}'"}]'

