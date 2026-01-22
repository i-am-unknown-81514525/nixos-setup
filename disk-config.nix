{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vdb"; # QEMU sees vda; label handles it on real hardware
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
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              mountpoint = "legacy";
              copies = "1";
              "com.sun:auto-snapshot" = "false"; # Don't snapshot the OS root
            };
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = { 
              atime = "off"; 
              copies = "1"; 
              "com.sun:auto-snapshot" = "false";
            };
          };
          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = { 
              copies = "2";
              "com.sun:auto-snapshot" = "false";
            };
          };
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options = { 
              copies = "2"; # Extra safety for keys/configs
              "com.sun:auto-snapshot" = "true"; 
            };
          };
        };
      };
    };
  };
}
