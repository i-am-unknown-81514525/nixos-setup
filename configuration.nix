{ config, pkgs, lib, inputs,... }: {
  # 1. BOOT & ZFS
  boot.loader.systemd-boot.enable = true;
  boot.supportedFilesystems = [ "zfs" ];

  # ZFS Rollback / Import logic
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zpool import -f zroot || true
  '';

  fileSystems."/etc/nixos" = {
    device = "/persist/etc/nixos";
    fsType = "none";
    options = [ "bind" ];
  };

  networking.hostId = "8425e349"; 
  networking.hostName = "framework";
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # 2. GRAPHICS FIX
  # The error in your image happens because mesa.vulkanDrivers is not a package.
  # On modern NixOS, the default drivers are included automatically.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-validation-layers
      vulkan-loader
      vulkan-tools
      # Removed mesa.vulkanDrivers as it causes the 'not of type package' error
    ];
  };

  # 3. DESKTOP SERVICES FIX
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;

  # Plasma 6 is now a Desktop Manager, not a Window Manager
  services.desktopManager.plasma6.enable = true;

  # 4. SYSTEM & HARDWARE
  boot.initrd.availableKernelModules = [ 
    "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" 
    "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_gpu"
  ];
  
  boot.kernelParams = [ "zfs.zfs_arc_max=8589934592" ];

  programs.niri.enable = true;
  programs.nix-ld.enable = true;
  
  networking.networkmanager.enable = true;
  system.stateVersion = "24.05";

  # 5. USERS
  users.users.root.initialPassword = "nixos";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
  };

  # 6. PERSISTENCE SNAPSHOTS
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
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = [
    pkgs.cloudflare-warp
    pkgs.systemd
    pkgs.cacert
    pkgs.alacritty-graphics
    pkgs.fuzzel
    pkgs.swaylock
  ];
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # networking.networkmanager.enable = true;
  # networking.wireless.enable = false;
  hardware.enableRedistributableFirmware = true;
  # boot.kernelParams = [ "pcie_aspm=off" ];
  services.cloudflare-warp.enable = true;

  services.libinput = {
    enable = true;

    touchpad = {
      tapping = true;
      naturalScrolling = true;
      middleEmulation = true;
      disableWhileTyping = true;
    };
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  security.pam.services.login.kwallet.enable = true;
  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
  ];
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
    };
  };
  fonts.fontconfig.localConf = ''
  <?xml version="1.0"?>
  <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  <fontconfig>
    <alias>
      <family>serif</family>
      <prefer><family>Noto Color Emoji</family></prefer>
    </alias>
    <alias>
      <family>sans-serif</family>
      <prefer><family>Noto Color Emoji</family></prefer>
    </alias>
    <alias>
      <family>monospace</family>
      <prefer><family>Noto Color Emoji</family></prefer>
    </alias>
  </fontconfig>
'';
}
