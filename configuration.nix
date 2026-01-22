{ config, pkgs, lib, inputs,... }: {
  # 1. BOOT & ZFS ROLLBACK
  boot.loader.systemd-boot.enable = true;
  boot.supportedFilesystems = [ "zfs" ];

  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zpool import -f zroot || true
  '';
  
  # CRITICAL: Fix ZFS import on different hardware. 
  networking.hostId = "8425e349"; 

  boot.kernelPackages = pkgs.linuxPackages_6_12;

  services.xserver = {
    enable = true;

    # Enable Wayland
    displayManager.gdm.enable = true; # GNOME Display Manager (required for GNOME or Plasma Wayland)
    displayManager.gdm.wayland = true;

    # For Plasma (if used)
    windowManager.plasma5.enable = true;
    windowManager.plasma5.enableWayland = true;
  };

  hardware.opengl = {
    enable = true;          # Enable OpenGL rendering
    driSupport = true;      # Enable Direct Rendering Interface (DRI) for hardware-accelerated graphics
    driSupport32Bit = true; # Enable 32-bit support for Vulkan (for gaming or specific needs)
    extraPackages = with pkgs; [
      vulkan-validation-layers # Optional, for Vulkan debug tools
      vulkan-loader            # Vulkan loader
      vulkan-tools             # Tools for Vulkan testing (e.g., `vkcube`)
      mesa.vulkanDrivers       # Add default Mesa Vulkan drivers for your GPU
    ];
  };

  boot.initrd.availableKernelModules = [ # QEMU
    "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" # Framework drivers
    "virtio_pci" "virtio_blk" "virtio_scsi"  "virtio_gpu"              # QEMU drivers (for verification)
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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ]; # 'wheel' gives you sudo access
  };
  services.sanoid = {
    enable = true;
    interval = "hourly"; # How often to check
    datasets."zroot/safe/persist" = {
      hourly = 24;
      daily = 7;
      monthly = 3;
      autoprune = true;
      autosnap = true;
    };
  };
}
