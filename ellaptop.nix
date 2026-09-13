{ config, pkgs, ... }:

# 🦄 Ellaptop — Dell Latitude 5501, converted from ChromeOS Flex.
#
# Confirmed via `lspci | grep -i vga` during install (2026-09-13): this unit
# is Intel UHD 630 (Coffee Lake) only, no discrete MX150 — unlike Locke, no
# hardware.nvidia/PRIME block is needed here.

{
  imports = [
    ./hardware-ellaptop.nix
    ./common.nix
    ./modules/kid-apps.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ellaptop";
  networking.networkmanager.enable = true; # wifi

  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false; # avoid the tlp/power-profiles-daemon conflict (see laptop.nix)

  # jade's admin account (wheel/networkmanager/docker, SSH) is already
  # declared fleet-wide in modules/base.nix via common.nix — nothing to add
  # here, same as how umaro.nix only layers on extra groups.

  # ella: her own everyday account, auto-login, no sudo.
  users.users.ella = {
    isNormalUser = true;
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "ella";
  };

  system.stateVersion = "26.05";
}
