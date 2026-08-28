{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  libevdev,
  xdotool,
}:
stdenv.mkDerivation rec {
  pname = "wayland-push-to-talk-fix";
  version = "unstable-2025-10-08";

  src = fetchFromGitHub {
    owner = "Rush";
    repo = "wayland-push-to-talk-fix";
    rev = "fecb045c90916ae0cd0414948e0af561dd9ea579";
    hash = "sha256-nvoeeOVBVm0GhTpsf8LkYUBXeRWDqdWuEO9FV8La13g=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libevdev
    xdotool
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 push-to-talk $out/bin/push-to-talk
    install -Dm644 push-to-talk.desktop $out/share/applications/push-to-talk.desktop
    runHook postInstall
  '';

  meta = with lib; {
    description = "Fix push to talk in Discord when running Wayland";
    homepage = "https://github.com/Rush/wayland-push-to-talk-fix";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "push-to-talk";
  };
}
