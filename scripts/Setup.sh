#!/bin/bash
wget -q raw.githubusercontent.com/PinkTurkey0/GentooInstall/main/configs/make.cfg &
wget -q raw.githubusercontent.com/PinkTurkey0/GentooInstall/main/scripts/Install.sh &
wget -q raw.githubusercontent.com/PinkTurkey0/GentooInstall/main/scripts/Chroot.sh & wait
chmod +x Install.sh Chroot.sh
echo "Downloading finished. You can modify the configuration files and then run the Install.sh script."