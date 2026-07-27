{ config, pkgs, ... }:

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
  # Ensure NFS tools are installed for automounting support
  boot.supportedFilesystems = [ "nfs" ];

  # Shared NAS NFS Mount (Automounts on-demand when accessed)
  fileSystems."/data" = { 
    device = "192.168.0.4:/volume1/data";
    fsType = "nfs4";
    options = [ 
      "x-systemd.automount" 
      "noauto" 
      "x-systemd.idle-timeout=600" 
      "x-systemd.device-timeout=5s" 
      "x-systemd.mount-timeout=5s" 
      "x-gvfs-hide"

      # 🛡️ The Kernel-Level Network Guardrails:
      "soft"        # Fail and return an I/O error instead of blocking indefinitely
      "timeo=14"    # Wait exactly 1.4 seconds before a retry (measured in tenths of a sec)
      "retrans=2"   # Retry only twice before giving up completely
    ];
  };
  
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
    vim wget htop p7zip curl ntfs3g docker-compose gparted solaar pavucontrol claude-code
    kdePackages.kate kdePackages.yakuake kdePackages.filelight kdePackages.kcalc

    # Baseline diagnostic toolkit — shared by every host in the flake.
    # NOTE: deliberately no `inetutils` — it collides with `nettools` over
    # hostname/ifconfig and breaks the systemPackages build.
    nettools        # ifconfig, netstat, route, arp
    dnsutils        # dig, nslookup — the validation tool for the DNS migration
    traceroute
    nmap tcpdump ethtool iperf3
    lsof tree jq ncdu iotop file unzip ripgrep
    pciutils        # lspci
    usbutils        # lsusb
    smartmontools   # disk health
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
