FROM ghcr.io/charles8191/rocky-bootc:r9

ARG EXCLUSIONS=PackageKit

# Shortly after IBM took over Red Hat, they removed KDE.
# So we have to use EPEL.
# EPEL recommends enabling CRB, so we do that too.

RUN dnf install epel-release -y && \
    dnf config-manager --set-enabled crb

# This will separate the biggest package to a new layer

RUN dnf install -x $EXCLUSIONS -y plasma-workspace

RUN dnf install -x $EXCLUSIONS -y \
     @fonts \
     @guest-desktop-agents \
     @hardware-support \
     @networkmanager-submodules \
     @print-client \
     alsa-firmware \
     alsa-sof-firmware \
     containernetworking-plugins \
     dolphin \
     firefox \
     flatpak \
     kcalc \
     konsole \
     kscreen \
     linux-firmware \
     man-db \
     mozilla-openh264 \
     plasma-breeze \
     plasma-discover \
     plasma-discover-flatpak \
     plasma-nm \
     plasma-systemmonitor \
     plasma-systemsettings \
     plymouth \
     plymouth-system-theme \
     sddm \
     sddm-breeze \
     wget \
     wpa_supplicant

RUN systemctl set-default graphical.target

# Fix Plymouth

RUN kver=$(cd /usr/lib/modules && echo * | awk '{print $1}') && \
    dracut -vf /usr/lib/modules/$kver/initramfs.img $kver

RUN ostree container commit && \
    bootc container lint
