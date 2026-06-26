{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-laptop.nix                 # [cite: 97]
    ./common.nix                          # 🌟 Pulls in all the shared configurations instantly!
  ];

  # Bootloader setup for UEFI laptops
  boot.loader.systemd-boot.enable = true; # [cite: 98]
  boot.loader.efi.canTouchEfiVariables = true; # [cite: 98]

  networking.hostName = "jade-laptop";    # [cite: 98]

  # Power management specialized for ThinkPads
  services.tlp.enable = true;             # [cite: 103]
  services.power-profiles-daemon.enable = false; # Prevents the CPU governor conflict

  # Enable the NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ]; # [cite: 107]
  hardware.graphics.enable = true;        # [cite: 107]
  hardware.nvidia = {
    modesetting.enable = true;             # [cite: 108]
    powerManagement.enable = true;         # [cite: 108]
    open = false;                         # MUST BE FALSE for the MX150 Pascal card [cite: 108, 109]
    nvidiaSettings = true;                 # [cite: 109]
    prime = {                             # [cite: 110]
      offload = {                         # [cite: 110]
        enable = true;                    # [cite: 110]
        enableOffloadCmd = true;          # [cite: 111]
      };
      intelBusId = "PCI:0:2:0";           # [cite: 111]
      nvidiaBusId = "PCI:2:0:0";          # [cite: 111]
    };
  };

  # NAS NFS Mount
  fileSystems."/data" = { 
    device = "192.168.0.4:/volume1/data";
    fsType = "nfs4";
  };

  system.stateVersion = "26.05";          # [cite: 120]
}