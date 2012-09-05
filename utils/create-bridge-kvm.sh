#!/bin/bash
#
#
## Danilo Ferri Perogil [20120904]: Script para subir VLAN e Rede na instalacao de images do KVM. Rode o script depois de instalar a image, execute na mesma pasta onde esta a image e demais arquivos.
# Base estudo: http://doc.opensuse.org/products/draft/SLES/SLES-kvm_sd_draft/cha.qemu.running.html
#
#

IMAGE='windowsR2008SP1.img'
BRIDGE=br100
TAP=$(sudo tunctl -u $(whoami) -b)

ip link set $TAP up
sleep 2
brctl addif $BRIDGE $TAP
kvm -m 4096 $IMAGE -net nic,vlan=0,model=virtio,macaddr=00:16:35:AF:94:4B -net TAP,vlan=0,ifname=$TAP,script=no,downscript=no -nographic -vnc :30
brctl delif $BRIDGE $TAP
ip link set $TAP down
tunctl -d $TAP
