#!/usr/bin/env bash
set -e

mkdir -p /etc/apt/keyrings

### Install helm and cli json processor which is helppfull for API parsing
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt update && apt install -y helm jq iptables

echo "We need legacyiptables in Debian 10 for DNS and stuff to work"
update-alternatives --set iptables /usr/sbin/iptables-legacy

### Install RKE2 server
curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL=v1.24.4+rke2r1 sh -
systemctl enable --now rke2-server.service

### There is kubectl and some useful tools in rke2 directory
echo -e "\nPATH=\"/var/lib/rancher/rke2/bin:$PATH\"" >> /root/.bashrc
echo -e "\nPATH=\"/var/lib/rancher/rke2/bin:$PATH\"" >> /home/vagrant/.bashrc
export PATH="/var/lib/rancher/rke2/bin:$PATH"

### Copy the kubeconfig to relevant places for convenient access
mkdir /home/vagrant/.kube && cp /etc/rancher/rke2/rke2.yaml /home/vagrant/.kube/config && chown -R vagrant: /home/vagrant/.kube
mkdir /root/.kube && cp /etc/rancher/rke2/rke2.yaml /root/.kube/config

helm repo add jetstack https://charts.jetstack.io
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

# Install the cert-manager Helm chart
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.7.1 --set installCRDs=true --wait --timeout 20m

### Give the system some time as otherwise the ingress throws errors
### @todo Add check if systems are up
sleep 30

### Add Rancher for Kubernetes management
helm install rancher rancher-stable/rancher --namespace cattle-system --create-namespace --set replicas=1 --set bootstrapPassword=admin --set hostname=${HOSTNAME} --wait --timeout 20m

while true; do
  sleep 10
  ### Getting rancher inside the loop is needed, as it could not be up yet
  RANCHER_POD=$(kubectl -n cattle-system get pods -l app=rancher | grep '1/1' | head -1 | awk '{ print $1 }')
  kubectl -n cattle-system exec ${RANCHER_POD} -- curl -sLk https://127.0.0.1/ping && break
  echo "Rancher is not up"
done

### Add local-path storage class
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.23/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

sleep 30

echo "create a Token"
while true; do
	TOKEN=`kubectl -n cattle-system exec ${RANCHER_POD} -- curl -sLk "https://127.0.0.1/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure | jq -r .token`
  if [ "$TOKEN" != "null" ]; then break; else sleep 5; fi
done

## change password
kubectl -n cattle-system exec ${RANCHER_POD} -- curl -sLk 'https://127.0.0.1/v3/users?action=changepassword' -H 'content-type: application/json' -H "Authorization: Bearer $TOKEN" --data-binary '{"currentPassword":"admin","newPassword":"'thisisunsafe'"}' --insecure

### Wait some time so everything can come up correctly before shutting it down
sleep 120