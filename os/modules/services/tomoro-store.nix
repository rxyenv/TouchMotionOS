{ config, lib, pkgs, ... }:

let
  platform = pkgs.callPackage ../../../platform { };
in
{
  systemd.services.tomoro-store = {
    description = "Tomoro Store IPC daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    environment = {
      TOMORO_BACKEND = "http://localhost:8000";
    };

    path = [ pkgs.steam-run ];

    serviceConfig = {
      ExecStart = "${platform}/bin/tomoro-store";
      User = "tomoro";
      Restart = "on-failure";
      RestartSec = "2s";
      RuntimeDirectory = "tomoro";
      StateDirectory = "tomoro";
    };
  };
}
