{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda"; # QEMU sees vda; label handles it on real hardware
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "zstd";   # Global zstd compression
          "com.sun:auto-snapshot" = "false";
        };
        datasets = {
          # --- Ephemeral / Reproducible Data (Efficiency) ---
          "local" = {
            type = "zfs_fs";
            options = { mountpoint = "none"; copies = "1"; };
          };
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy"; # Required for rollback
            # Create the blank snapshot for ephemeral root
            postCreateHook = "zfs snapshot zroot/local/root@blank";
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = { atime = "off"; copies = "1"; };
          };

          # --- Persistent / User Data (Redundancy) ---
          "safe" = {
            type = "zfs_fs";
            options = { mountpoint = "none"; copies = "2"; };
          };
          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = { copies = "2"; "com.sun:auto-snapshot" = "true"; };
          };
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options = { copies = "2"; };
          };
        };
      };
    };
  };
}
