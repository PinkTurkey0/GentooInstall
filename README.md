# GentooInstall
GentooInstall is a TUI installer for Gentoo Linux
## How to use
Run `net-setup` to connect to wifi

Run `wget raw.githubusercontent.com/PinkTurkey0/GentooInstall/main/scripts/Setup.sh` to download the setup

Run `chmod +x Setup.sh` to make the setup executable

Run `./Setup.sh` to download the .cfg and .sh files
## Notes
- Only works with 64-bit UEFI installations without modifications
- Locales and timezones need to be manually configured (See [here](https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation#Configure_locales) for locales and [here](https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation#Timezone) for timezones)
## TODO
- [X] TUI
- [ ] Compressed RAM
- [ ] Disk encryption
- [ ] Time and locale selection
- [ ] Optional desktop selection
- [ ] Support for other architectures