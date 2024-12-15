#!/usr/bin/env bash
set -e

mkdir -p /etc/apt/keyrings

### Install helm and cli json processor which is helppfull for API parsing
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt update && apt install -y helm jq

### Install k3s server
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb" sh -s -

echo "Get kubectl working https://rancher.com/docs/k3s/latest/en/cluster-access/"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
grep -q KUBECONFIG /root/.profile || echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /root/.profile
chown vagrant:vagrant /etc/rancher/k3s/k3s.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

# Install nginx
helm install nginx ingress-nginx/ingress-nginx --namespace kube-system --set rbac.create=true,controller.hostNetwork=true,controller.dnsPolicy=ClusterFirstWithHostNet,controller.kind=DaemonSet,controller.ingressClass=nginx,controller.ingressClassResource.default=true

# Install the cert-manager Helm chart
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.16.2 --set installCRDs=true --wait --timeout 20m

### Add Rancher for Kubernetes management
helm install rancher rancher-stable/rancher --namespace cattle-system --create-namespace --set replicas=1 --set bootstrapPassword=admin --set hostname=${HOSTNAME} --wait --timeout 20m

while true; do
  sleep 10
  ### Getting rancher inside the loop is needed, as it could not be up yet
  RANCHER_POD=$(kubectl -n cattle-system get pods -l app=rancher | grep '1/1' | head -1 | awk '{ print $1 }')
  kubectl -n cattle-system exec ${RANCHER_POD} -- curl -sLk https://127.0.0.1/ping && break
  echo "Rancher is not up"
done

echo "create a Token"
while true; do
	TOKEN=`kubectl -n cattle-system exec ${RANCHER_POD} -- curl -sLk "https://127.0.0.1/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure | jq -r .token`
  if [ "$TOKEN" != "null" ]; then break; else sleep 5; fi
done

## change password
kubectl -n cattle-system exec ${RANCHER_POD} -- curl -sLk 'https://127.0.0.1/v3/users?action=changepassword' -H 'content-type: application/json' -H "Authorization: Bearer $TOKEN" --data-binary '{"currentPassword":"admin","newPassword":"'thisisunsafe'"}' --insecure

### Wait some time so everything can come up correctly before shutting it down
sleep 15