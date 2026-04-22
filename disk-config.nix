{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # QEMU sees vda; label handles it on real hardware
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
          "local/games" = {
            type = "zfs_fs";
            mountpoint = "/mnt/games";
            mountOptions = [ "nofail" ];
            options = {
              copies = "1";
              "com.sun:auto-snapshot" = "false";
              compression = "lz4";
              xattr = "sa";
              atime = "off";
              recordsize = "1M";
              mountpoint = "legacy";
            };
          };
          "local/user/vm" = {
            type = "zfs_fs";
            mountpoint = "/home/user/.local/share/gnome-boxes/images";
            mountOptions = [ "nofail" ];
            options = {
              copies = "1";
              "com.sun:auto-snapshot" = "false";
              compression = "lz4";
              xattr = "sa";
              atime = "off";
              recordsize = "64k";
              mountpoint = "legacy";
            };
          };
          "local/docker/overlay2" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/docker/overlay2";
            mountOptions = [ "nofail" ];
            options = {
              copies = "1";
              "com.sun:auto-snapshot" = "false";
              compression = "zstd";
              xattr = "sa";
              atime = "off";
              recordsize = "64k";
              mountpoint = "legacy";
            };
          };
          "local/docker/buildkit" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/docker/buildkit";
            mountOptions = [ "nofail" ];
            options = {
              copies = "1";
              "com.sun:auto-snapshot" = "false";
              compression = "lz4";
              xattr = "sa";
              atime = "off";
              recordsize = "64k";
              mountpoint = "legacy";
            };
          };
        };
      };
    };
  };
}
