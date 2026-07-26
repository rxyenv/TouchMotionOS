{ slot ? "a", ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./hardware.nix
    ./disko.nix
    ../../modules/system/quiet-boot.nix
    ../../modules/system/plymouth-theme.nix
    ../../modules/system/autologin.nix
    ../../modules/kiosk
    ../../modules/system/debug-ssh.nix
    ../../modules/system/ota-update.nix
    ../../modules/services/python-server.nix
    ../../modules/services/tomoro-store.nix
  ];

  services.tomoro-server = {
    enable = true;
    dataDir = "/data";
  };

  # Filesystems by label — both disko and the legacy installer script format
  # the disk with these labels, so this config works on any target disk
  # (sda/nvme/...). A/B: the slot arg (flake specialArgs) picks which system
  # partition this closure mounts as /. disko.enableConfig=false keeps disko
  # as format-only; these label-based mounts stay the single source of truth.
  disko.enableConfig = false;
  fileSystems."/" = {
    device = "/dev/disk/by-label/tomoro-${slot}";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/TOMORO-ESP";
    fsType = "vfat";
  };
  # Shared mutable state; survives A/B slot switches.
  fileSystems."/data" = {
    device = "/dev/disk/by-label/tomoro-data";
    fsType = "ext4";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  networking.useDHCP = true;

  system.stateVersion = "26.11";
}
