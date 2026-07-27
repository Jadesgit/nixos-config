{ config, pkgs, ... }:

# Settings every host in this flake gets — desktop or headless server.
# Anything requiring a graphical session, audio, or Bluetooth belongs in
# ./desktop.nix instead, because umaro is headless and must not pull KDE in.

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

  networking.hosts = { "192.168.0.3" = ["pi.hole"]; };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 2234 9000 8096 21115 21116 21117 21118 21119 ];
    allowedUDPPorts = [ 59010 59011 9000 21116 19132 ];
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };

  # NFS client support — needed wherever the NAS is mounted
  boot.supportedFilesystems = [ "nfs" ];

  virtualisation.docker.enable = true;
  services.openssh.enable = true;

  # Base User
  users.users.jade = {
    isNormalUser = true;
    description = "jade";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  environment.systemPackages = with pkgs; [
    vim wget htop p7zip curl ntfs3g docker-compose claude-code

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

  # Experimental Features Enabled Natively
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Automation for system maintenance
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings.auto-optimise-store = true;
  };
}
