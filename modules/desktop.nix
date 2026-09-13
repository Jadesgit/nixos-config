{ config, pkgs, ... }:

# Graphical-workstation concerns: KDE, audio, Bluetooth, printing, Flatpaks.
# Imported by terra and locke via common.nix. NOT imported by headless hosts
# like umaro — pulling this into a server drags in all of Plasma.

{
  services.mullvad-vpn.enable = true;

  # Hardware / Audio / Desktop Environment Base
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      ControllerMode = "bredr";
    };
  };
  hardware.logitech.wireless.enable = true;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };

  # Audio & Core Services
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  ###services.pipewire = { alsa.enable = true; alsa.support32Bit = true; pulse.enable = true; };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Dumb down Bluetooth for buggy firmware
    wireplumber.extraConfig."11-bluetooth-tweaks" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
      "monitor.bluez.properties" = {
        "bluez5.enable-hw-volume" = false;
        "bluez5.roles" = [ "a2dp_sink" "a2dp_source" ];
      };
    };
  };

  programs.dconf.enable = true;
  programs.kdeconnect.enable = true;

  # Make GTK apps read desktop settings (fonts, theme, DPI) through the KDE
  # xdg-desktop-portal instead of GTK's Wayland defaults. Without this,
  # Firefox 153 on Plasma Wayland reads GTK's unset font DPI (-1) and computes
  # a *negative* chrome font size — all UI text (tabs, urlbar, menus) becomes
  # invisible while page content renders fine. Verified fix on terra 2026-07-31.
  # Side benefit: GTK apps get native KDE file dialogs.
  environment.sessionVariables.GTK_USE_PORTAL = "1";

  environment.systemPackages = with pkgs; [
    solaar pavucontrol
    kdePackages.kate kdePackages.yakuake kdePackages.filelight kdePackages.kcalc
    kdePackages.kclock
  ];

  services.flatpak = {
    enable = true;
    packages = [
      "org.videolan.VLC"
      "md.obsidian.Obsidian"
      "com.bitwarden.desktop"
      "com.calibre_ebook.calibre"
      "org.nicotine_plus.Nicotine"
    ];
  };
}
