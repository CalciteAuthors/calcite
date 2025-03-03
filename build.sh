#!/bin/bash
set -euxo pipefail

# Quick fixes

## Make sure rootfiles can install
mkdir -m 0700 -p /var/roothome

## Without this, dracut causes issues
ln -sf /run /var/run

## Prevent automatic reboots
sed -i 's,ExecStart=/usr/bin/bootc update --apply --quiet,ExecStart=/usr/bin/bootc update --quiet,g' \
  /usr/lib/systemd/system/bootc-fetch-apply-updates.service

## Hide the small loop device in Files
echo 'KERNEL=="loop0", ENV{UDISKS_IGNORE}="1"' > /etc/udev/rules.d/10-bootc.rules

# Packages

## GNOME Desktop
### Exclusion justifications
#### cockpit - Slightly harden the system, and it's pretty useless on a desktop anyway
#### {kmod-k,}vdo - Speed up build times, and it's pretty useless
#### PackageKit{,-command-not-found} - Prevent issues in GNOME Software, and it's pretty useless in this environment
dnf install -x cockpit,kmod-kvdo,PackageKit,PackageKit-command-not-found,vdo -y \
  alsa-sof-firmware \
  @base \
  centos-backgrounds \
  firefox \
  @fonts \
  gdm \
  @gnome-desktop \
  @guest-desktop-agents \
  @hardware-support \
  man-db \
  @networkmanager-submodules \
  @print-client

## Remove terminal errors
dnf remove -y console-login-helper-messages{,profile}

## Add more DNF functionality
dnf install -y dnf-plugins-core

# System configuration

## Add Flathub
mkdir -p /etc/flatpak/remotes.d
curl -o /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

## Firewall
dnf install -y firewalld
systemctl enable firewalld

## Make GDM and everything needed appear
systemctl set-default graphical.target

# Dracut

## Rebuild initramfs. Largely fixes Plymouth.
kver=$(cd /usr/lib/modules && echo * | awk '{print $1}')
dracut -vf /usr/lib/modules/$kver/initramfs.img $kver

# Cleanup

## Clean DNF cache
dnf clean all

## Lint with bootc
bootc container lint

## Commit with ostree
ostree container commit
