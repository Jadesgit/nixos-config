{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ./common.nix 
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "terra";
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