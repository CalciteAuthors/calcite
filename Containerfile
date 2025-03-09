FROM ghcr.io/charles8191/rocky-bootc:r9

ARG EXCLUSIONS=PackageKit

# A package would create /var/run, this is a fix

RUN ln -sf /run /var/run

# Shortly after IBM took over Red Hat, they removed KDE.
# So we have to use EPEL.
# EPEL recommends enabling CRB, so we do that too.

RUN dnf install epel-release -y && \
    dnf config-manager --set-enabled crb

# This will separate the biggest package to a new layer

RUN dnf install -x $EXCLUSIONS -y plasma-workspace

# Fix rootfiles

RUN mkdir -m 0700 -p /var/roothome

RUN dnf install -x $EXCLUSIONS -y \
     @base \
     @core \
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
     rootfiles \
     sddm \
     sddm-breeze \
     wget \
     wpa_supplicant

RUN systemctl set-default graphical.target

# System would have random reboots due to auto updates from bootc

RUN sed -i 's,ExecStart=/usr/bin/bootc update --apply --quiet,ExecStart=/usr/bin/bootc update --quiet,g' \
  /usr/lib/systemd/system/bootc-fetch-apply-updates.service

# Plymouth wouldn't show otherwise

RUN kver=$(cd /usr/lib/modules && echo * | awk '{print $1}') && \
    dracut -vf /usr/lib/modules/$kver/initramfs.img $kver

RUN ostree container commit && \
    bootc container lint
