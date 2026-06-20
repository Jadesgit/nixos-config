{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # VPNs & Networking
  services.tailscale.enable = true;
  services.mullvad-vpn.enable = true;
  networking.hosts = { "192.168.0.3" = ["pi.hole"]; };
  
  # Firewall Config
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 2234 9000 8096 21115 21116 21117 21118 21119 ];
  networking.firewall.allowedUDPPorts = [ 59010 59011 9000 21116 19132 ];
  networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];

  # Hardware / Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.logitech.wireless.enable = true;
  time.timeZone = "America/Denver";

  # Locales
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8"; LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8"; LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8"; LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8"; LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Desktop Environment (Plasma 6)
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };
  
  # XRDP
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  services.xrdp.openFirewall = true;

  # Sound, Printing, Containers
  services.printing.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = { alsa.enable = true; alsa.support32Bit = true; pulse.enable = true; };
  virtualisation.docker.enable = true;
  programs.dconf.enable = true;
  programs.kdeconnect.enable = true;
  services.openssh.enable = true;

  # Single User Setup (Goodbye jaderdp!)
  users.users.jade = {
    isNormalUser = true;
    description = "jade";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # System Utilities
  environment.systemPackages = with pkgs; [
    vim wget htop p7zip curl ntfs3g docker-compose gparted solaar
    kdePackages.kate kdePackages.yakuake kdePackages.filelight kdePackages.kcalc
  ];

  # Declarative Flatpak Lists!
  services.flatpak = {
    enable = true;
    packages = [
      "org.videolan.VLC"
      "md.obsidian.Obsidian"
      "com.bitwarden.desktop"
      "com.calibre_ebook.calibre"
    ];
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "23.05"; # Keep your original stateVersion!
}