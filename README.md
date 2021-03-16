# OpenShift 4 Installation

## Pre-requisites

### On your local machine

Install Terraform.

```sh
cat > hashicorp.repo <<"EOF"
[hashicorp]
name=Hashicorp Stable - $basearch
baseurl=https://rpm.releases.hashicorp.com/RHEL/8/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://rpm.releases.hashicorp.com/gpg
EOF
sudo dnf config-manager --add-repo hashicorp.repo
sudo dnf -y install terraform
```

Install the libvirt terraform provider.

```sh
curl -Lo /tmp/libvirt-provider.tgz https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.3/terraform-provider-libvirt-0.6.3+git.1604843676.67f4f2aa.Fedora_32.x86_64.tar.gz
mkdir -p ~/.terraform.d/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64
tar xvf /tmp/libvirt-provider.tgz -C ~/.terraform.d/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64
```

Install the Gandi terraform provider.

```sh
git clone https://github.com/go-gandi/terraform-provider-gandi
cd terraform-provider-gandi
make
make install
```

### On the hypervisor

```sh
curl https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.7/4.7.0/rhcos-4.7.0-x86_64-qemu.x86_64.qcow2.gz |gunzip -c > /var/lib/libvirt/images/rhcos-4.7.0-x86_64-qemu.x86_64.qcow2
curl -Lo /var/lib/libvirt/images/centos-stream-8.qcow2 http://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20210210.0.x86_64.qcow2
```

## Install

Define the cluster name and the bastion.

```sh
cluster=ocp4
bastion=nicolas@hp-ml350.itix.fr
```

Install **openshift-installer** and **oc** on the bastion.

```sh
ssh -A "$bastion" curl -Lo /tmp/openshift-installer.tgz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.7/openshift-install-linux.tar.gz
ssh -A "$bastion" sudo tar zxvf /tmp/openshift-installer.tgz -C /usr/local/bin openshift-install
ssh -A "$bastion" curl -Lo /tmp/oc.tgz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.7/openshift-client-linux.tar.gz
ssh -A "$bastion" sudo tar zxvf /tmp/oc.tgz -C /usr/local/bin oc kubectl
```

Create the cluster configuration files.

```sh
mkdir "$cluster"
cp install-config.yaml.sample "$cluster/install-config.yaml"
openshift-install create manifests --dir="$cluster"
openshift-install create ignition-configs --dir="$cluster"
```

Customize the terraform variables.

```sh
cat > terraform.tfvars <<EOF
base_domain = "itix.xyz"
external_mac_address = "02:00:00:00:00:04"
public_cluster_ip = "90.79.1.247"
cluster_name = "$cluster"
EOF
```

Apply the terraform plan.

```sh
export GANDI_KEY="123...456"
terraform apply
```

Copy the cluster definition on the bastion and run the bootstrap process from there.

```sh
scp -r "$cluster" "$bastion:'$cluster'"
ssh -A "$bastion" openshift-install --dir="$cluster" wait-for bootstrap-complete --log-level=info
```

Delete the bootstrap node.

```sh
echo 'bootstrap_nodes = 0' >> terraform.tfvars
terraform apply
```

Approve the pending CSRs.

```sh
for i in {0..120}; do
  ssh -A "$bastion" oc --kubeconfig="$cluster/auth/kubeconfig" get csr --no-headers \
    | awk '/Pending/ {print $1}' \
    | xargs --no-run-if-empty ssh -A "$bastion" oc --kubeconfig="$cluster/auth/kubeconfig" adm certificate approve
  sleep 15
done &
```

Make sure all CSRs have been issued.

```sh
ssh -A "$bastion" oc --kubeconfig="$cluster/auth/kubeconfig" get csr --no-headers
```

Provision storage for the registry.

```sh
ssh -A "$bastion" oc apply --kubeconfig="$cluster/auth/kubeconfig" -f - < "$cluster/registry-pv.yaml"
```

Patch the registry to use the new storage.

```sh
ssh -A "$bastion" oc patch --kubeconfig="$cluster/auth/kubeconfig" configs.imageregistry.operator.openshift.io cluster --type='json' --patch-file=/dev/fd/0 <<EOF
[{"op": "remove", "path": "/spec/storage" },{"op": "add", "path": "/spec/storage", "value": {"pvc":{"claim": "registry-storage"}}}]
EOF
```

Deploy the NFS provisioner.

```sh
ssh -A "$bastion" oc apply --kubeconfig="$cluster/auth/kubeconfig" -f - < "$cluster/nfs-provisioner.yaml"
```

Set image registry managementState from Removed to Managed.

```sh
ssh -A "$bastion" oc patch --kubeconfig="$cluster/auth/kubeconfig" configs.imageregistry.operator.openshift.io cluster --type merge --patch-file=/dev/fd/0 <<EOF
{"spec":{"managementState": "Managed"}}
EOF
```

Wait for installation to finish.

```sh
ssh -A "$bastion" openshift-install --dir="$cluster" wait-for install-complete
```

## Let's encrypt certificates

Install lego.

```sh
curl -Lo /tmp/lego.tgz https://github.com/go-acme/lego/releases/download/v4.3.1/lego_v4.3.1_linux_amd64.tar.gz
sudo tar zxvf /tmp/lego.tgz -C /usr/local/bin lego
```

Request a public certificate.

```sh
export GANDIV5_API_KEY="123...456"
. "$cluster/dns.env"
lego -m "nmasse@redhat.com" -d "$LE_API_HOSTNAME" -d "$LE_ROUTER_HOSTNAME" -a --dns gandi run --no-bundle
```

Create a secret containing the new router certificate.

```sh
oc create secret tls router-certs-$(date "+%Y-%m-%d") --cert=$HOME/.lego/certificates/$LE_API_HOSTNAME.crt --key=$HOME/.lego/certificates/$LE_API_HOSTNAME.key -n openshift-ingress --dry-run -o yaml > router.yaml
ssh -A "$bastion" oc apply -f - -n openshift-ingress < router.yaml
```

Update the ingress configuration.

```sh
ssh -A "$bastion" oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch-file=/dev/fd/0 <<EOF
{"spec": { "defaultCertificate": { "name": "$(date "+%Y-%m-%d")" }}}
EOF
```

Create a secret containing the new certificate.

```sh
oc create secret tls api-certs-$(date "+%Y-%m-%d") --cert=$HOME/.lego/certificates/$LE_API_HOSTNAME.crt --key=$HOME/.lego/certificates/$LE_API_HOSTNAME.key -n openshift-config --dry-run -o yaml > api.yaml
ssh -A "$bastion" oc apply -f - -n openshift-config < api.yaml
```

Update the apiserver configuration.

```sh
oc patch apiserver cluster --type=merge --patch-file=/dev/fd/0 <<EOF
{"spec":{"servingCerts":{"namedCertificates":[{"names":["'$LE_API'"],"servingCertificate":{"name": "api-certs-$(date "+%Y-%m-%d")"}}]}}}
EOF
