# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  ####TEMPFIX
  # boot.initrd.systemd.network.wait-online.enable = false;  
  #systemd.network.wait-online.enable = false;


  # Enable networking
  networking.networkmanager.enable = true;
  # Enable Tailscale
  services.tailscale.enable = true;
  services.mullvad-vpn.enable=true;
  # Enable Bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  hardware.logitech.wireless.enable = true; #Allows logitech wireless with solaar
  # Set your time zone.
  time.timeZone = "America/Denver";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  services.xrdp.openFirewall = true;
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
 #  Mount point for NAS moved to hardwareconfiguration.nix
 #  fileSystems."/data" = {
 #   device = "192.168.0.4:/volume1/Data/media/plex";
 #   fsType = "nfs4";
 #  options = ["x-systemd.automount" "noauto" ];
 #  };



  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Enable Flatpaks for GUI apps
  services.flatpak.enable = true;
  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.users.jade = {
    isNormalUser = true;
    description = "jade";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox
      git
      soundwireserver
      vscode
      bitwarden
      python314
      vscode-extensions.hashicorp.terraform
      latte-dock
      vlc
      pkgs.widevine-cdm
#      (pkgs.overlays.pkgs.unstable.vlc)
      libvlc
      easytag
      terraform
      #nicotine-plus	
      libusb1
      awscli
      mpv
      obsidian
    ];
  };
  users.users.jaderdp = {
    isNormalUser = true;
    description = "jaderdp";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    hashedPassword = "$y$j9T$0.iqCxcyXtKy3C534TY6j1$dzrZaeGYouv24O14OkJuI1OhuUV1B9shdAAgl//KkS2";
    packages = with pkgs; [
      firefox
      git
      soundwireserver
      vscode
      bitwarden
      python314
      vscode-extensions.hashicorp.terraform
      latte-dock
      vlc
#      (pkgs.overlays.pkgs.unstable.vlc)
      libvlc
      terraform
      nicotine-plus
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
 
  #Enable Programs dconf for GTK apps {easytag in this case}
  programs.dconf.enable=true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    htop
    p7zip
    kdePackages.kate
    kdePackages.yakuake
    kdePackages.filelight
    kdePackages.kcalc
    curl
    ntfs3g
    docker-compose
    gparted
    pkgs.solaar
    pkgs.calibre
];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  # enableSSHSupport = true;
  # };

  # List services that you want to enable:
  #KDEConnect
  programs.kdeconnect.enable = true;
  # Enable the OpenSSH daemon.
   services.openssh.enable = true;

  # Enable docker
   virtualisation.docker.enable = true;
  # users.users.jade.extraGroups = [ "docker" ];

  # Hosts file entries
   networking.hosts = {
  "192.168.0.3" = ["pi.hole"];
}; 

  # Open ports in the firewall.
   #networking.firewall.allowedTCPPorts = [ 80 443 2234 9000 8096 21115 21116 21117 21118 21119 ];
    networking.firewall.allowedTCPPorts = [ 80 443 2234 9000 8096 21115 21116 21117 21118 21119];
    networking.firewall = rec {
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
    };
    networking.firewall.allowedUDPPorts = [ 59010 59011 9000 21116 19132 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
