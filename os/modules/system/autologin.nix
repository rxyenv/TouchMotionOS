{ lib, ... }:

{
  # Cage owns tty1. Start an explicit, independent debug shell on tty2;
  # relying on systemd's on-demand virtual-terminal gettys leaves kiosk
  # installs with no usable way to inspect failures.
  services.getty.autologinUser = lib.mkForce "tomoro";

  systemd.services."getty@tty2".wantedBy = [ "getty.target" ];
}
