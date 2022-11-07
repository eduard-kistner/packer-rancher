#!/usr/bin/env bash
set -e

echo "wait until rancher is ready"
while true; do
  sleep 10
  docker exec -t rancher curl -sLk https://127.0.0.1/ping && break
done

echo "create a Token"
while true; do
	TOKEN=`docker exec -t rancher curl "https://127.0.0.1/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure | jq -r .token`
  if [ "$TOKEN" != "null" ]; then break; else sleep 5; fi
done

### Setup cluster access @see https://rancher.com/docs/k3s/latest/en/cluster-access/
docker exec -t rancher curl -X POST 'https://127.0.0.1/v3/clusters/local?action=generateKubeconfig' -H "Authorization: Bearer $TOKEN" --insecure | jq -r .config > /opt/k8s.yaml
mkdir /home/vagrant/.kube && cp /opt/k8s.yaml /home/vagrant/.kube/config && chown -R vagrant: /home/vagrant/.kube
mkdir /root/.kube && cp /opt/k8s.yaml /root/.kube/config