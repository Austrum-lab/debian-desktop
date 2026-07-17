# TKG Kernel for ASUS G14

Configs and Patches I use to build kernel with TKG for my ASUS ROG Zephyrus G14 2023 (GA402XY) with bore scheduler.

Can be usable for all laptops, ASUS in particular.

## Build Configuration

| Parameter | Value |
|-----------|-------|
| **Version** | 7.1-latest |
| **Scheduler** | BORE |
| **Compiler** | GCC 15 |
| **CPU Optimization** | x86-64-v4 |
| **HZ** | 1000 |
| **TCP Congestion** | BBR |

## Sources

- **TKG:** https://github.com/Frogging-Family/linux-tkg
- **linux-g14 kernel:** https://gitlab.com/asus-linux/linux-g14

## Build Instructions

### 1. Clone TKG repo && launch install script

```bash
git clone https://github.com/Frogging-Family/linux-tkg.git
```

### 2. Copy configs

```bash
mkdir ~/.config/frogminer/ && cp linux-tkg.cfg ~/.config/frogminer/
cp g14_7_1.config linux-tkg/ # copy config from repository to pulled tkg folder
cp -r linux71-tkg-userpatches linux-tkg/ # copy patches from repository to pulled tkg folder
```

### 3. Launch tkg install script

```bash
cd linux-tkg
sudo ./install.sh install
```

### 4. Sign Kernel (for Secure Boot)

see scripts/sign-kernel.sh

## Building a new version
```bash
cd linux-tkg && sudo rm DEBS/*.deb
git stash push -u && git pull --rebase origin master && git stash pop 0
sudo ./install.sh install
```
