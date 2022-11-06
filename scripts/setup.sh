#!/usr/bin/env bash
set -e

apt update && apt install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings

### Add docker to sources list
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list

### Add kubectl to sources list
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

### Add helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin kubectl helm

echo "Enable ( unsecure ) docker remote access and add vagrant user to docker group to allow usage"
usermod -a -G docker vagrant
sed -i 's#ExecStart=/usr/bin/dockerd#ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375#' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker

echo "We need legacyiptables in Debian 10 for DNS and stuff to work"
update-alternatives --set iptables /usr/sbin/iptables-legacy

