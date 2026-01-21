{ config, pkgs, lib, inputs,... }: {
  # 1. BOOT & ZFS ROLLBACK
  boot.loader.systemd-boot.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  
  # CRITICAL: Fix ZFS import on different hardware. 
  networking.hostId = "8425e349"; 

  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.initrd.availableKernelModules = [ # QEMU
    "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" # Framework drivers
    "virtio_pci" "virtio_blk" "virtio_scsi"                # QEMU drivers (for verification)
  ];
  
  # Limit ZFS ARC to 8GB (value in bytes)
  boot.kernelParams = [ "zfs.zfs_arc_max=8589934592" ];

  # 2. GRAPHICS & NIRI
  programs.niri.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  
  # 4. NIX-LD (Binary Compatibility)
  programs.nix-ld.enable = true;
  
  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true; # For WiFi drivers
  system.stateVersion = "24.05";

  users.users.root.initialPassword = "nixos";

  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ]; # 'wheel' gives you sudo access
  };
}
