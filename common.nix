{ config, pkgs, antigravity-nix, ... }:

{
  # Global System Settings
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8"; LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8"; LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8"; LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8"; LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Network & Security
  services.tailscale.enable = true;
  services.mullvad-vpn.enable = true;
  networking.hosts = { "192.168.0.3" = ["pi.hole"]; };
  
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 2234 9000 8096 21115 21116 21117 21118 21119 ];
    allowedUDPPorts = [ 59010 59011 9000 21116 19132 ];
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };

  # Hardware / Audio / Desktop Environment Base
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.logitech.wireless.enable = true;
  
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };

  # Audio & Core Services
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = { alsa.enable = true; alsa.support32Bit = true; pulse.enable = true; };
  
  virtualisation.docker.enable = true;
  programs.dconf.enable = true;
  programs.kdeconnect.enable = true;
  services.openssh.enable = true;

  # Base User
  users.users.jade = {
    isNormalUser = true;
    description = "jade";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

 # Shared System Packages & Flatpaks
  environment.systemPackages = with pkgs; [
    vim wget htop p7zip curl ntfs3g docker-compose gparted solaar pavucontrol
    kdePackages.kate kdePackages.yakuake kdePackages.filelight kdePackages.kcalc

    # 🌟 Updated from pkgs.system to stdenv.hostPlatform.system
    antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default                 
    antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide  
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

  # Experimental Features Enabled Natively
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Automation for system maintenance (Now inside the braces! 🎉)
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d"; 
    };
    settings.auto-optimise-store = true; 
  };
}