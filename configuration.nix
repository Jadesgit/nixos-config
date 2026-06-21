{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ./common.nix # 🌟 Pulls in all the shared stuff instantly
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos";
  system.stateVersion = "23.05";
}