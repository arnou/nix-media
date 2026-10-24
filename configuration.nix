{ config, lib, pkgs, ... }:
let
  mediaApp = pkgs.runCommand "media-center-app" {} ''
    mkdir -p $out
    cp ${./app/server.py} $out/server.py
    cp ${./app/index.html} $out/index.html
  '';
  startMenu = pkgs.writeShellScript "start-media-center" ''
    for i in $(seq 1 60); do
      if ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:8765/health >/dev/null; then break; fi
      sleep 1
    done
    exec ${pkgs.chromium}/bin/chromium \
      --user-data-dir="$HOME/.local/share/media-center-chromium" \
      --no-first-run --disable-session-crashed-bubble \
      --kiosk http://127.0.0.1:8765/
  '';
in {
  networking.hostName = "media-center";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
  };

  console.keyMap = "fr";
  services.xserver.xkb.layout = "fr";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.media = {
    isNormalUser = true;
    description = "Compte Media Center";
    extraGroups = [ "networkmanager" "video" "audio" ];
    initialPassword = "media";
  };

  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.settings.General.Numlock = "on";
  services.displayManager.defaultSession = "plasma";
  services.displayManager.autoLogin = { enable = true; user = "media"; };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  hardware.enableRedistributableFirmware = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    kodi chromium firefox mpv vlc ffmpeg libva-utils curl pciutils usbutils vim kdePackages.kio-extras kdePackages.kio-fuse libmtp git
  ];

  systemd.user.services.media-center-server = {
    description = "Local Media Center launcher";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 ${mediaApp}/server.py ${mediaApp}/index.html ${pkgs.kodi}/bin/kodi";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  environment.etc."xdg/autostart/media-center.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Media Center
    Exec=${startMenu}
    Terminal=false
    X-KDE-autostart-after=panel
  '';
  environment.etc."xdg/kwalletrc".text = ''
    [Wallet]
    Enabled=false
  '';
  # Modifier après installation selon le besoin.
  system.stateVersion = "26.05";
}
