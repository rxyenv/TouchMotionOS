{ config, lib, pkgs, ... }:

let
  platform = pkgs.callPackage ../../../platform { };
  python = pkgs.python3.withPackages (ps: [ ps.fastapi ps.uvicorn ]);
in
{
  systemd.services.tomoro-catalog = {
    description = "Tomoro game catalog API";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      ExecStart = "${python}/bin/python -m uvicorn main:app --host 127.0.0.1 --port 8000";
      WorkingDirectory = "${../../../backend}";
      User = "tomoro";
      StateDirectory = "tomoro-catalog";
      Restart = "on-failure";
      RestartSec = "2s";
      Environment = "DB_PATH=/var/lib/tomoro-catalog/catalog.db";
    };
  };

  systemd.services.tomoro-store = {
    description = "Tomoro Store IPC daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "tomoro-catalog.service" ];
    wants = [ "network-online.target" ];
    requires = [ "tomoro-catalog.service" ];

    environment = {
      TOMORO_BACKEND = "http://localhost:8000";
    };

    path = [ pkgs.unzip ];

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
