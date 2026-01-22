{ config, pkgs, lib, inputs,... }: {
  # 1. BOOT & ZFS ROLLBACK
  boot.loader.systemd-boot.enable = true;
  boot.supportedFilesystems = [ "zfs" ];

  # Note: It is often better to use 'postResumeCommands' to avoid race conditions
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zpool import -f zroot || true
  '';

  fileSystems."/etc/nixos" = {
    device = "/persist/etc/nixos";
    fsType = "none";
    options = [ "bind" ];
  };

  networking.hostId = "8425e349"; 
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # 2. DESKTOP SERVICES
  services.xserver.enable = true;
  
  # MODERN WAY: Display Manager and Desktop Manager are separate
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;

  # FIX: Plasma is now a Desktop Manager, and 'plasma6' is the modern name
  services.desktopManager.plasma6.enable = true;

  # 3. GRAPHICS (MODERN SYNTAX)
  # hardware.opengl was renamed to hardware.graphics in 24.11
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Replaces driSupport32Bit
    # driSupport is no longer needed/has no effect in 24.11
    
    extraPackages = with pkgs; [
      vulkan-validation-layers
      vulkan-loader
      vulkan-tools
      mesa.vulkanDrivers
    ];
  };

  # 4. SYSTEM & DRIVERS
  boot.initrd.availableKernelModules = [ 
    "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" 
    "virtio_pci" "virtio_blk" "virtio_scsi"  "virtio_gpu"
  ];
  
  boot.kernelParams = [ "zfs.zfs_arc_max=8589934592" ];

  programs.niri.enable = true;
  programs.nix-ld.enable = true;
  
  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";

  # 5. USERS & STORAGE
  users.users.root.initialPassword = "nixos";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
  };

  services.sanoid = {
    enable = true;
    interval = "hourly";
    datasets."zroot/safe/persist" = {
      hourly = 24;
      daily = 7;
      monthly = 3;
      autoprune = true;
      autosnap = true;
    };
  };
}
