{ lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Simulated wifi radios (wlan0/wlan1) — QEMU has no wifi NIC, this lets
  # the settings screen's wifi detection be exercised in the VM.
  boot.kernelModules = [ "mac80211_hwsim" ];

  # wlan0 = station (settings screen connects with it); wlan1 = test AP.
  networking.wireless.interfaces = [ "wlan0" ];

  # qemu-vm.nix disables wpa_supplicant with mkVMOverride (priority 10);
  # out-prioritize it — the whole point of this VM is testing wifi.
  virtualisation.vmVariant.networking.wireless.enable = lib.mkOverride 9 true;

  services.tomoro-server = {
    enable = true;
    dataDir = "/var/lib/tomoro-data";
  };

  services.hostapd = {
    enable = true;
    radios.wlan1 = {
      band = "2g";
      channel = 6;
      networks.wlan1 = {
        ssid = "TOMORO Test";
        authentication = {
          mode = "wpa2-sha256";
          wpaPassword = "tomoro123";
        };
      };
    };
  };

  # DHCP for clients that join the test AP, so the station gets an
  # address and the settings screen shows Connected.
  networking.interfaces.wlan1.ipv4.addresses = [
    { address = "192.168.42.1"; prefixLength = 24; }
  ];
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "wlan1";
      bind-interfaces = true;
      dhcp-range = "192.168.42.10,192.168.42.100,12h";
    };
  };

  imports = [
    ../../modules/services/python-server.nix
    ../../modules/system/boot.nix
    ../../modules/system/plymouth-theme.nix
    ../../modules/system/autologin.nix
    ../../modules/kiosk
    ../../modules/system/debug-ssh.nix
  ];
}
