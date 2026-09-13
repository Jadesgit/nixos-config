{ config, pkgs, ... }:

# 🦄 Ellaptop — Dell Latitude 5501, converted from ChromeOS Flex.
#
# NOTE on hardware.nvidia: the 5501 ships with and without a discrete MX150.
# Do not assume laptop.nix's (Locke's) PRIME block applies — check
# `lspci | grep -i vga` during install and only add an nvidia section, with
# this machine's own bus IDs, if a discrete GPU actually shows up.

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
