{ pkgs, lib, modulesPath, self, ... }:

let
  # Pre-built appliance system; shipped in the ISO's nix store so the
  # installer needs no network and no on-target compilation.
  applianceSystem = self.nixosConfigurations.appliance.config.system.build.toplevel;

  tomoroInstall = pkgs.writeShellApplication {
    name = "tomoro-install";
    runtimeInputs = with pkgs; [
      gptfdisk
      dosfstools
      e2fsprogs
      coreutils
      util-linux
      nixos-install-tools
    ];
    text = ''
      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0" "$@"
      fi

      disk="''${1:-}"
      if [ -z "$disk" ]; then
        echo
        echo "=== Install TOMORO OS ==="
        echo
        mapfile -t disks < <(lsblk -dpno NAME,SIZE,MODEL,TYPE | awk '$NF=="disk" {$NF=""; print}')
        if [ "''${#disks[@]}" -eq 0 ]; then
          echo "No disks found." >&2
          exit 1
        fi
        echo "Target disk (ALL DATA ON IT WILL BE ERASED):"
        select choice in "''${disks[@]}"; do
          [ -n "$choice" ] && break
        done
        disk=$(awk '{print $1}' <<< "$choice")
      fi

      echo
      read -rp "Erase $disk and install TOMORO OS? Type 'yes' to continue: " answer
      [ "$answer" = "yes" ] || exit 1

      echo ">>> Partitioning $disk (A/B layout)"
      wipefs -a "$disk"
      sgdisk --zap-all "$disk"
      sgdisk -n1:0:+512MiB -t1:ef00 -c1:ESP "$disk"
      sgdisk -n2:0:+16GiB  -t2:8300 -c2:slot-a "$disk"
      sgdisk -n3:0:+16GiB  -t3:8300 -c3:slot-b "$disk"
      sgdisk -n4:0:0       -t4:8300 -c4:data "$disk"
      partprobe "$disk" || true
      udevadm settle

      case "$disk" in
        *[0-9]) p="p" ;;
        *) p="" ;;
      esac

      echo ">>> Formatting"
      mkfs.fat -F32 -n TOMORO-ESP "''${disk}''${p}1"
      mkfs.ext4 -F -L tomoro-a "''${disk}''${p}2"
      mkfs.ext4 -F -L tomoro-b "''${disk}''${p}3"
      mkfs.ext4 -F -L tomoro-data "''${disk}''${p}4"
      udevadm settle

      echo ">>> Mounting slot A"
      mount /dev/disk/by-label/tomoro-a /mnt
      mkdir -p /mnt/boot /mnt/data
      mount /dev/disk/by-label/TOMORO-ESP /mnt/boot
      mount /dev/disk/by-label/tomoro-data /mnt/data

      echo ">>> Installing pre-built TOMORO system (offline)"
      nixos-install --system ${applianceSystem} --no-root-passwd --no-channel-copy

      echo
      echo ">>> Done. Remove the USB stick and reboot."
    '';
  };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  environment.systemPackages = [ tomoroInstall ];

  # Ship the appliance closure inside the ISO so nixos-install works offline.
  isoImage.storeContents = [ applianceSystem ];

  image.baseName = lib.mkForce "touchmotionOS";
  # zstd builds much faster than the default xz at a small size cost.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  services.getty.helpLine = lib.mkForce ''

    === TOMORO OS installer ===
    Run `tomoro-install` to erase a disk and install TOMORO OS.
  '';

  networking.hostName = "tomoro-installer";
}
