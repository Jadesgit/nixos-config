{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ./common.nix 
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "Terra";
  system.stateVersion = "23.05";
}