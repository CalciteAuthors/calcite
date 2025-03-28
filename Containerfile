FROM ghcr.io/charles25565/rocky-bootc:a10s

# Software stores typically break because they attempt to install an RPM and it doesn't work

ARG EXCLUSIONS=PackageKit

# Fix /opt and /usr/local

RUN mv /opt /var/opt && \
  ln -sf /var/opt /opt

RUN mv /usr/local /var/usrlocal && \
  ln -sf /var/usrlocal /usr/local

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
     @fonts \
     @guest-desktop-agents \
     @hardware-support \
     @input-methods \
     @networkmanager-submodules \
     @print-client \
     alsa-firmware \
     alsa-sof-firmware \
     ark \
     dolphin \
     dnf-plugins-core \
     f41-backgrounds-base \
     firefox \
     firewalld \
     flatpak \
     git \
     kate \
     kcalc \
     konsole \
     kscreen \
     linux-firmware \
     man-db \
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
     sddm-kcm \
     spectacle \
     toolbox \
     wget \
     wpa_supplicant

# Fix terminal error messages

RUN dnf remove -y console-login-helper-messages{,-profile}

# Fix white SDDM

# RUN ln -s ./f41/default/f41-01-day.png /usr/share/backgrounds/default.png

RUN systemctl set-default graphical.target

# System would have random reboots due to auto updates from bootc

RUN sed -i 's,ExecStart=/usr/bin/bootc update --apply --quiet,ExecStart=/usr/bin/bootc update --quiet,g' \
  /usr/lib/systemd/system/bootc-fetch-apply-updates.service

RUN systemctl enable firewalld

# Plymouth wouldn't show otherwise

RUN kver=$(cd /usr/lib/modules && echo * | awk '{print $1}') && \
    depmod -a $kver && \
    dracut -vf /usr/lib/modules/${kver}/initramfs.img $kver

RUN bootc container lint
