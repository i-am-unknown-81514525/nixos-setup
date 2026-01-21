{ config, pkgs, lib, inputs,... }: {
  # 1. BOOT & ZFS ROLLBACK
  boot.loader.systemd-boot.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  
  # CRITICAL: Fix ZFS import on different hardware. 
  networking.hostId = "8425e349"; 

  # Reset root
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    # Wait for the device to appear
    sleep 2 
    # Try to import if not already there, then rollback
    zpool import -f zroot || true
    zfs rollback -r zroot/local/root@blank
  '';
  
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

  # 3. PERSISTENCE (WiFi, Bluetooth, Keys)
  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key"
    ];
  };
  
  # 4. NIX-LD (Binary Compatibility)
  programs.nix-ld.enable = true;
  
  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true; # For WiFi drivers
  system.stateVersion = "24.05";
}
