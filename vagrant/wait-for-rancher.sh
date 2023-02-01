#!/usr/bin/env bash

while true; do
  sleep 10
  ### Getting rancher inside the loop is needed, as it could not be up yet
  RANCHER_POD=$(kubectl -n cattle-system get pods -l app=rancher | grep '1/1' | head -1 | awk '{ print $1 }')

  echo "$RANCHER_POD"

  kubectl -n cattle-system exec ${RANCHER_POD} -- curl -sLk https://127.0.0.1/ping && break
  echo "Rancher is not up"
done