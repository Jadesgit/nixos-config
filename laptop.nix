# Bootloader setup for UEFI laptops
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Power management specialized for ThinkPads
  services.tlp.enable = true;

  # Enable the NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # Dynamic power management to turn off GPU when idle
    open = false;                  # MUST BE FALSE for the MX150 Pascal card
    nvidiaSettings = true;

    # NVIDIA PRIME Hybrid Offloading
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # Gives you the 'nvidia-offload' command wrapper
      };
      
      # Bus IDs will be fetched via `lspci` on the laptop once booted
      intelBusId = "PCI:0:2:0"; 
      nvidiaBusId = "PCI:1:0:0";
    };
  };