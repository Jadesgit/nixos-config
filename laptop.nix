{ config, pkgs, ... }:

{
  imports = [ ./hardware-laptop.nix ];

  # Bootloader setup for UEFI laptops
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "jade-laptop";
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

  # Power management specialized for ThinkPads
  services.tlp.enable = true;

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

  # Enable the NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; 
    open = false; # MUST BE FALSE for the MX150 Pascal card
    nvidiaSettings = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; 
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0"; # Updated with your verified Bus ID!
    };
  };

  # Desktop Environment (Plasma 6)
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };

  # Sound, Printing, Containers
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = { alsa.enable = true; alsa.support32Bit = true; pulse.enable = true; };
  virtualisation.docker.enable = true;
  programs.dconf.enable = true;
  programs.kdeconnect.enable = true;
  services.openssh.enable = true;

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

  # Declarative Flatpaks
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

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";
}