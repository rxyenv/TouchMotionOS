{ stdenv
, autoPatchelfHook
, makeWrapper
, alsa-lib
, libglvnd
, libpulseaudio
, udev
, vulkan-loader
, libx11
, libxcursor
, libxext
, libxi
, libxinerama
, libxrandr
, libxrender
, zlib
, libdecor
, wayland
, cairo
, pango
}:

stdenv.mkDerivation {
  pname = "tomoro-yogaflow";
  version = "0.1.0";

  src = ./game;

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    libglvnd
    libpulseaudio
    libx11
    libxcursor
    libxext
    libxi
    libxinerama
    libxrandr
    libxrender
    zlib
    libdecor
    wayland
    cairo
    pango
  ];

  runtimeDependencies = [ libglvnd libpulseaudio udev vulkan-loader libdecor ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/yogaflow $out/bin
    cp -r Yoga_Flow_Data UnityPlayer.so Yoga_Flow.x86_64 libdecor-0.so.0 libdecor-cairo.so $out/opt/yogaflow/
    chmod +x $out/opt/yogaflow/Yoga_Flow.x86_64

    makeWrapper $out/opt/yogaflow/Yoga_Flow.x86_64 $out/bin/tomoro-yogaflow \
      --chdir $out/opt/yogaflow \
      --set HOME /tmp

    runHook postInstall
  '';

  meta.description = "YogaFlow (Unity) for TOMORO";
}
