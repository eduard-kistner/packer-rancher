#!/usr/bin/env bash
set -e

### Starting Rancher
docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v /opt/rancher:/var/lib/rancher -e CATTLE_BOOTSTRAP_PASSWORD=admin --name rancher --privileged rancher/rancher:stable

while true; do
  sleep 10
  docker exec -t rancher curl -sLk https://127.0.0.1/ping && break
  echo "Rancher is not up"
done

echo "create a Token"
TOKEN=`docker exec -t rancher curl "https://127.0.0.1/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure | jq -r .token`

## change password
docker exec -t rancher curl -s 'https://127.0.0.1/v3/users?action=changepassword' -H 'content-type: application/json' -H "Authorization: Bearer $TOKEN" --data-binary '{"currentPassword":"admin","newPassword":"'thisisunsafe'"}' --insecure

### Add local-path storage class
docker exec -t rancher kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.23/deploy/local-path-storage.yaml
docker exec -t rancher kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'