#!/bin/bash
set -e
source etc/profile
rm -rf /etc/portage/package.use
emerge-webrsync || emerge --sync
emerge -uDN @world
emerge app-admin/doas sys-kernel/linux-firmware sys-apps/pciutils sys-boot/grub
emerge --oneshot app-portage/cpuid2cpuflags sys-fs/genfstab sys-kernel/genkernel
echo "*/* $(cpuid2cpuflags)" >> /etc/portage/package.use
if [ "$Kernel" = "vanilla-sources" ]; then
    emerge sys-kernel/vanilla-sources
    eselect kernel set 1
    cd /usr/src/linux
    make menuconfig
    make -j"$(nproc)" && make modules_install && make install && genkernel --install --kernel-config=.config initramfs
fi
if [ "$Kernel" = "vanilla-kernel" ]; then
    echo "sys-kernel/vanilla-kernel initramfs" >> /etc/portage/package.use
    emerge sys-kernel/vanilla-kernel
    eselect kernel set 1
fi
if [ "$Kernel" = "gentoo-sources" ]; then
    emerge sys-kernel/gentoo-sources
    eselect kernel set 1
    cd /usr/src/linux
    make menuconfig
    make -j"$(nproc)" && make modules_install && make install && genkernel --install --kernel-config=.config initramfs
fi
if [ "$Kernel" = "gentoo-kernel" ]; then
    echo "sys-kernel/gentoo-kernel initramfs" >> /etc/portage/package.use
    emerge sys-kernel/gentoo-sources
    eselect kernel set 1
fi
if [ "$Kernel" = "gentoo-sources-experimental" ]; then
    echo "sys-kernel/gentoo-sources experimental" >> /etc/portage/package.use
    emerge sys-kernel/gentoo-sources
    eselect kernel set 1
    cd /usr/src/linux
    make menuconfig
    make -j"$(nproc)" && make modules_install && make install && genkernel --install --kernel-config=.config initramfs
fi
genfstab -U / > /etc/fstab
echo "permit persist :wheel" > /etc/doas.conf
echo "$Hostname" > /etc/hostname
emerge net-misc/networkmanager
emerge --depclean app-admin/sudo && emerge --depclean
echo "GRUB_GFXPAYLOAD_LINUX=keep" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
echo "min=1,1,1,1,1
max=256
passphrase=1
match=1
similar=permit
random=0
enforce=everyone
retry=3" > /etc/security/passwdqc.conf
useradd "$Username"
usermod -aG wheel "$Username"
echo -e "$Password\n$Password" | passwd root
echo -e "$Password\n$Password" | passwd "$Username"
echo "clear" >> /home/"$Username"/.bashrc
unset ExperimentalKernel Kernel Password Hostname Username
clear && echo "Installation completed."