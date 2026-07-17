# Debian Desktop

Debian Testing desktop configuration for home usage with laptop (i'm on ASUS ROG Zephyrus G14 2023 [GA402XY])

Repo contains some files, scripts and configs and info about using debian testing as desktop OS with GNOME / KDE Plasma

## Repository Structure

| Path | Description |
|------|-------------|
| `scripts/` | Sync, install and maintenance scripts (repo-sync, sign-kernel, etc.) |
| `etc/` | System configs (apt, modprobe, sysctl, environment.d, asusd, dbus) |
| `.config/` | User configs (MangoHud, PipeWire, environment.d, frogminer, autostart) |
| `.bashrc` | Shell config |
| `tkg-kernel/` | TKG kernel configs and patches |
| `easyeffects-presets/` | EasyEffects audio presets |

## Kernel Build

See [tkg-kernel/README.md](tkg-kernel/README.md) for detailed instructions.

## More Info

- [Software List](software-list.txt)
- [GNOME Extensions](gnome-extensions-list.txt)
