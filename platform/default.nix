{ rustPlatform, makeWrapper, iw, wpa_supplicant }:

rustPlatform.buildRustPackage {
  pname = "tomoro-platform";
  version = "0.1.0";

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/tomoro-net \
      --prefix PATH : ${iw}/bin:${wpa_supplicant}/bin
  '';

  meta.description = "TOMORO platform binaries (tomoro-net network detection)";
}
