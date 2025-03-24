#!/bin/bash

# This launches a VM.
# You will need localhost/calcite:a10s in root's container storage. To do that, run this as root:
# # podman build -t localhost/calcite:a10s .
# Alternatively, use another URL in the CONTAINER environment variable.

set -euxo pipefail
name=$(uuidgen)
container=${CONTAINER:-localhost/calcite:a10s}

cd ~/.cache

cat > ${name}.cf <<EOF
FROM $container
RUN useradd -m user
RUN usermod -aG wheel user
RUN echo user:password | chpasswd
EOF

sudo podman build -t $name -f ${name}.cf

truncate -s 16G ${name}.img

sudo podman run \
     --rm \
     --privileged \
     --pid=host \
     --security-opt label=type:unconfined_t \
     -v /dev:/dev \
     -v /var/lib/containers:/var/lib/containers \
     -v .:/output \
     $name \
      bootc install to-disk \
       --generic-image \
       --via-loopback \
       --skip-fetch-check \
       --filesystem=xfs \
       /output/${name}.img

set +x
echo "+---------------------+"
echo "| VM is now running.  |"
echo "| User: user          |"
echo "| Password: password  |"
echo "| VNC: 127.0.0.1:5907 |"
echo "+---------------------+"
set -x

export qemu=/bin/false
test -f /usr/libexec/qemu-kvm && \
 export qemu=/usr/libexec/qemu-kvm
test -f /usr/bin/qemu-system-$(uname -m) && \
 export qemu=/usr/bin/qemu-system-$(uname -m)

$qemu \
 -M q35 \
 -cpu host \
 -accel kvm \
 -m 2G \
 -smp 2 \
 -vga virtio \
 -display vnc=127.0.0.1:7 \
 -hda ${name}.img

rm -f ${name}.img
podman image rm -f $name

cd -
