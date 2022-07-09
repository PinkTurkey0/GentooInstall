#!/bin/bash
set -e
if ! ( whiptail --title "Continue?" --yesno --defaultno "To use the installer you need to overwrite a disk. Do you want to continue?" 8 80 ); then
    echo "User exited installer."; exit 0
fi
while true; do
    if [ "$Selection" = "Install" ]; then
        break
    fi
    if [ "$Selection" = "Exit" ]; then
        echo "User exited installer."; exit 0
    fi
    Selection=$(whiptail --title "GentooInstall" --menu --nocancel "Select an option to configure" $LINES $COLUMNS $(( LINES - 8 )) \
    "Hostname" "Set the systems hostname" \
    "Username" "Set the non-root accounts username" \
    "Password" "Set the root and non-root account passwords" \
    "Kernel" "Set the type of kernel you want to use" \
    "Disk" "Set the disk you want to install to" \
    "Swap" "Set the amount of swap you want to use" \
    "Install" "Install with the current configurations." \
    "Exit" "Exit the installer without making any changes." 3>&1 1>&2 2>&3)
    if [ "$Selection" = "Hostname" ]; then
        Hostname=$(whiptail --title "Hostname" --inputbox --nocancel "Enter the hostname you want to use." 8 39 3>&1 1>&2 2>&3)
    fi
    if [ "$Selection" = "Username" ]; then
        Username=$(whiptail --title "Username" --inputbox --nocancel "Enter the username you want to use." 8 39 3>&1 1>&2 2>&3)
    fi
    if [ "$Selection" = "Password" ]; then
        function VerifyPassword {
            Password=$(whiptail --title "Password 1/2" --passwordbox --nocancel "Enter the password you want to use for both your root and non-root account." 8 80 3>&1 1>&2 2>&3)
            VerifyPassword=$(whiptail --title "Password 2/2" --passwordbox --nocancel "Verify the password you want to use for both your root and non-root account." 8 80 3>&1 1>&2 2>&3)
            if [ "$Password" != "$VerifyPassword" ]; then
                whiptail --title "Password" --msgbox "Passwords do not match. Please try again." 8 45
                VerifyPassword
            fi
        }
        VerifyPassword
    fi
    if [ "$Selection" = "Kernel" ]; then
        Kernel=$(whiptail --title "Kernel" --radiolist --nocancel "Select a kernel" 10 93 5 \
        "vanilla-sources" "Use the vanilla kernel sources" OFF \
        "vanilla-kernel" "Use the premade vanilla kernel" OFF \
        "gentoo-sources" "Use the patched gentoo kernel sources" OFF \
        "gentoo-kernel" "Use the patched and premade gentoo kernel" OFF \
        "gentoo-sources-experimental" "Use the experimental patched gentoo kernel sources" OFF 3>&1 1>&2 2>&3)
    fi
    if [ "$Selection" = "Disk" ]; then
        InstallDisk=$(whiptail --title "Disk" --inputbox --nocancel "What disk do you want to install to? Disks: $(lsblk -nd --output NAME,SIZE)" 11 47 3>&1 1>&2 2>&3)
    fi
    if [ "$Selection" = "Swap" ]; then
        SwapSize=$(whiptail --title "Swap" --inputbox --nocancel "How many GB swap do you want to use?" 8 40 3>&1 1>&2 2>&3)
    fi
done
echo -e "g\nw" | fdisk /dev/"$InstallDisk" # GPT partition table
echo -e "n\n\n\n+128m\nw" | fdisk /dev/"$InstallDisk" # Boot partition
if [ "$SwapSize" = "0" ]; then
    RootPartition="${InstallDisk}2"
    echo -e "n\n\n\n-1\nw" | fdisk /dev/"$InstallDisk" # Root partition
else
    RootPartition="${InstallDisk}3"
    echo -e "n\n\n\n+${SwapSize}m\nw" | fdisk /dev/"$InstallDisk" # Swap partition
    echo -e "n\n\n\n-1\nw" | fdisk /dev/"$InstallDisk" # Root partition
    mkswap /dev/"${InstallDisk}2"
    swapon /dev/"${InstallDisk}2"
fi
mkfs.fat -F32 /dev/"${InstallDisk}1"
mkfs.ext4 /dev/"$RootPartition"
mount /dev/"$RootPartition" /mnt/gentoo
mv make.cfg /mnt/gentoo
mv Chroot.sh /mnt/gentoo
cd /mnt/gentoo
whiptail --title "Message" --msgbox "To successfully install, you need to download the stage3.tar.xz and the stage3.tar.xz.asc. Press enter to continue to the Gentoo downloads page." 8 78
links gentoo.org/downloads/mirrors
wget -O - https://qa-reports.gentoo.org/output/service-keys.gpg | gpg --import
if ( ! gpg --verify *.tar.xz.asc *.tar.xz ); then
    echo "Error at $LINENO: GPG verification failed."; exit 1
fi
tar xpvf *.tar.xz --xattrs-include='*.*' --numeric-owner && rm -rf *.tar.xz *.tar.xz.asc
mkdir boot/efi
mount /dev/"${InstallDisk}1" boot/efi
mv make.cfg etc/portage/make.conf
mkdir --parents etc/portage/repos.conf
cp usr/share/portage/config/repos.conf etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf etc/
mirrorselect -s5 -b10 -o -D >> etc/portage/make.conf
export ExperimentalKernel=$ExperimentalKernel Kernel=$Kernel Password=$Password Hostname=$Hostname Username=$Username
mount --types proc /proc proc
mount --rbind /sys sys
mount --make-rslave sys
mount --rbind /dev dev
mount --make-rslave dev
mount --bind /run run
mount --make-slave run
chroot /mnt/gentoo ./Chroot.sh