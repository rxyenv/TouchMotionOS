{ pkgs, lib, config, ... }:

let
  cfg = config.services.tomoro-server;

  serverSrc = pkgs.stdenv.mkDerivation {
    name = "tomoro-python-server-src";
    src = ../../../Server;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp requirements.txt $out/
      cp PythonServer.py $out/
    '';
  };

  sitePackages = "${cfg.dataDir}/python-packages";
in
{
  options.services.tomoro-server = {
    enable = lib.mkEnableOption "Tomoro Python Pose Server";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/data";
      description = "Persistent directory for pip packages. Use /data on appliance, override for VM.";
    };
  };

  config = lib.mkIf cfg.enable {
    # tomoro user needs camera access for mediapipe pose detection
    users.users.tomoro.extraGroups = [ "video" ];

    # Expose packages system-wide via PYTHONPATH
    environment.variables.PYTHONPATH = sitePackages;

    # One-shot: pip install into dataDir (persistent across A/B slots).
    # Re-runs only when requirements.txt changes (keyed by store hash).
    systemd.services.tomoro-server-setup = {
      description = "Tomoro Python server — system-wide package install";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      before = [ "tomoro-server.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p ${sitePackages}
        marker="${sitePackages}/.installed-${builtins.hashFile "sha256" (serverSrc + "/requirements.txt")}"
        if [ ! -f "$marker" ]; then
          ${pkgs.python3Packages.pip}/bin/pip3 install \
            --no-cache-dir \
            --target ${sitePackages} \
            -r ${serverSrc}/requirements.txt
          touch "$marker"
        fi
      '';
    };

    systemd.services.tomoro-server = {
      description = "Tomoro Python Pose Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "tomoro-server-setup.service" "network.target" ];
      requires = [ "tomoro-server-setup.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${serverSrc}/PythonServer.py";
        WorkingDirectory = "/var/lib/tomoro-server";
        StateDirectory = "tomoro-server";
        User = "tomoro";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [
          "PYTHONPATH=${sitePackages}"
          "LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc
            pkgs.zlib
            pkgs.libxcb
            pkgs.libGL
            pkgs.glib
            pkgs.libgcc
          ]}"
        ];
      };
    };
  };
}
