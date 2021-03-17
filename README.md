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

Install lego.

```sh
curl -Lo /tmp/lego.tgz https://github.com/go-acme/lego/releases/download/v4.3.1/lego_v4.3.1_linux_amd64.tar.gz
sudo tar zxvf /tmp/lego.tgz -C /usr/local/bin lego
```

### On the server

Install libvirt.

```sh
sudo dnf install libvirt libvirt-daemon-kvm virt-install virt-viewer virt-top libguestfs-tools nmap-ncat
```

Configure NetworkManager to use dnsmasq. In **/etc/NetworkManager/NetworkManager.conf**:

```ini
[main]
dns=dnsmasq
```

Download the required images.

```sh
curl https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.7/4.7.0/rhcos-4.7.0-x86_64-qemu.x86_64.qcow2.gz |gunzip -c > /var/lib/libvirt/images/rhcos-4.7.0-x86_64-qemu.x86_64.qcow2
curl -Lo /var/lib/libvirt/images/centos-stream-8.qcow2 http://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20210210.0.x86_64.qcow2
```

## Install

Create the template files from their sample.

```sh
cp terraform.tfvars.sample terraform.tfvars
cp local.env.sample local.env
cp install-config.yaml.sample install-config.yaml
```

Initialize a new cluster.

```sh
./cluster init my-cluster
```

Deploy the cluster.

```sh
./cluster apply my-cluster
```

Do the post-install on the cluster.

```sh
./cluster post-install my-cluster
```
