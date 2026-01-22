# Understanding nixos-enter and /mnt in NixOS Installation

## What makes nixos-enter think the system is in /mnt instead of /?

The `nixos-enter` command assumes the new NixOS system is mounted at `/mnt` by **convention**, not by any inherent configuration in your repository. This is a standard practice in NixOS installation workflows.

## Why /mnt?

### 1. **Installation Convention**
When you're installing NixOS on a fresh system, you're typically running from a live installation medium (USB/ISO). Your live system has its own root filesystem at `/`, and you need a place to mount the target filesystem where you want to install NixOS. By convention, `/mnt` is used as the mount point for the new system.

### 2. **Disko's Role**
In your repository, you're using `disko` (via `cmd1.sh`):
```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode destroy,format,mount ./disk-config.nix
```

When Disko runs with the `mount` mode, it:
- Formats the disk according to `disk-config.nix`
- **Mounts the new filesystem hierarchy at `/mnt`**
- Sets up all the ZFS datasets and boot partition at `/mnt`

Looking at your `disk-config.nix`, Disko will create this structure:
- `/mnt` - root (from `zroot/local/root`)
- `/mnt/boot` - ESP partition
- `/mnt/nix` - Nix store (from `zroot/local/nix`)
- `/mnt/home` - User home directories (from `zroot/safe/home`)
- `/mnt/persist` - Persistent data (from `zroot/safe/persist`)

### 3. **nixos-enter's Default Behavior**
The `nixos-enter` command has `/mnt` hardcoded as its default root. From the NixOS manual:
```
nixos-enter [ --root /mnt ] [ --system SYSTEM ] [ --command COMMAND ]
```

If you don't specify `--root`, it defaults to `/mnt`. This is because:
- It's the standard mount point for new installations
- It avoids conflicts with the live system's `/`
- It's a well-known convention in the NixOS community

## Your Installation Workflow

Based on your repository, the typical workflow is:

1. **Boot from NixOS live media** (your running system is at `/`)
2. **Run Disko** (`cmd1.sh`): Formats and mounts the new system at `/mnt`
3. **Install NixOS**: Copy configuration files to `/mnt/etc/nixos/` and run:
   ```bash
   sudo nixos-install --flake .#framework
   ```
4. **Enter the new system** (optional, for troubleshooting):
   ```bash
   sudo nixos-enter
   ```
   This chroots into `/mnt`, making it appear as `/` from inside the chroot

## How to Use a Different Mount Point

If you wanted to use a different location instead of `/mnt`, you would:

1. **Tell Disko where to mount** (not directly supported, but you could mount manually)
2. **Tell nixos-enter**:
   ```bash
   sudo nixos-enter --root /my/custom/path
   ```
3. **Tell nixos-install**:
   ```bash
   sudo nixos-install --root /my/custom/path --flake .#framework
   ```

However, using `/mnt` is strongly recommended as it's the standard convention and is expected by most NixOS tooling and documentation.

## Summary

Nothing in **your repository** makes nixos-enter use `/mnt` - it's a standard NixOS installation convention. Disko mounts the new system there by default, and nixos-enter expects it there by default. This separation between the live system (`/`) and the target system (`/mnt`) is what allows you to install NixOS safely without interfering with the running installation media.
