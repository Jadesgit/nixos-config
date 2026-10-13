{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./common.nix
    ./modules/desktop-admin-tools.nix
    ./modules/clamscan.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "terra";

  # Terra had only ever used plain DHCP (hardware-configuration.nix), never
  # NetworkManager — so there was no nm-applet/plasma-nm backend for the
  # system tray widget to attach to (it just doesn't offer the widget at
  # all without the service running), and no GUI way to set a static IP
  # during an outage. Fixes the "networking GUI unusable when the network
  # dies" issue reported 2026-08-21. Overrides hardware-configuration.nix's
  # `networking.useDHCP = lib.mkDefault true` cleanly since that's a default.
  networking.networkmanager.enable = true;

  # Weekly AV sweep of the Plex library; NAS is mounted on demand at /data.
  homelab.clamscan = {
    enable = true;
    paths = [ "/home/jade/Downloads" "/data/plex" ];
  };

  system.stateVersion = "23.05";

  # WirePlumber configuration to persist "Pro Audio" profiles on desktop audio cards
  # to allow legacy PortAudio applications like SoundWire Server to capture at 44.1kHz.
  services.pipewire.wireplumber.extraConfig = {
    "10-pro-audio" = {
      "wireplumber.settings" = {
        "device.restore-profile" = false;
      };
      "monitor.alsa.rules" = [
        {
          matches = [
            { "device.name" = "alsa_card.pci-0000_00_03.0"; }
            { "device.name" = "alsa_card.pci-0000_00_1b.0"; }
          ];
          actions = {
            update-props = {
              "device.profile" = "pro-audio";
            };
          };
        }
      ];
    };
  };
}