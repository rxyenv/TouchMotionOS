{ config, lib, pkgs, ... }:

let
  service = pkgs.writeShellApplication {
    name = "tomoro-remote-setup";
    runtimeInputs = [ pkgs.bluez pkgs.python3 ];
    text = ''exec ${pkgs.python3}/bin/python3 ${./tomoro-remote-setup.py}'';
  };
in {
  options.services.tomoro-remote-setup.enable = lib.mkEnableOption "Tomoro Irusu remote pairing service";

  config = lib.mkIf config.services.tomoro-remote-setup.enable {
    hardware.bluetooth = { enable = true; powerOnBoot = true; settings.General = { ControllerMode = "dual"; FastConnectable = true; }; };
    environment.systemPackages = [ service ];
    systemd.tmpfiles.rules = [ "d /data/tomoro 0700 root root -" ];
    systemd.services.tomoro-remote-setup = {
      description = "Tomoro LAN Irusu remote setup";
      wantedBy = [ "multi-user.target" ];
      after = [ "bluetooth.target" "data.mount" ];
      wants = [ "bluetooth.target" ];
      serviceConfig = {
        ExecStart = "${service}/bin/tomoro-remote-setup";
        Restart = "on-failure";
        RestartSec = 2;
        User = "root";
        NoNewPrivileges = false;
        PrivateTmp = true;
      };
    };
  };
}
