{ config, pkgs, ... }:

{
  imports = [
    ./hardware-laptop.nix                 # [cite: 97]
    ./common.nix                          # 🌟 Pulls in all the shared configurations instantly!
    ./modules/desktop-admin-tools.nix
    ./modules/emulation.nix
    ./modules/tdarr-node.nix
  ];

  # Same RetroArch/Dolphin/Pegasus suite as ellaptop (see modules/emulation.nix)
  # — locke's discrete MX150 handles GameCube/Wii (Dolphin) much better than
  # ellaptop's Intel UHD 630 can.
  emulation = {
    enable = true;
    user = "jade";
  };

  # Bootloader setup for UEFI laptops
  boot.loader.systemd-boot.enable = true; # [cite: 98]
  boot.loader.efi.canTouchEfiVariables = true; # [cite: 98]

  networking.hostName = "locke";
  networking.networkmanager.enable = true; # Required for Wi-Fi to work on laptops!

  # --- Power (TLP; power-profiles-daemon would fight it over the governor) ---
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_BOOST_ON_BAT = 0;
      PLATFORM_PROFILE_ON_BAT = "low-power";
      # Battery longevity: the T580 can hold charge between thresholds.
      # Before a trip: `sudo tlp fullcharge` charges to 100% once.
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      START_CHARGE_THRESH_BAT1 = 75;   # the optional external (rear) battery
      STOP_CHARGE_THRESH_BAT1 = 80;
      # Keep the Wi-Fi from dozing off on battery (causes lag/drops on Intel cards).
      WIFI_PWR_ON_BAT = "off";
    };
  };
  services.power-profiles-daemon.enable = false;

  # Compressed swap in RAM first; the disk swap partition stays as a fallback.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # --- Boot time (measured 2026-11-08: 17.6s userspace, mostly waiting) -------
  # Docker sat on the boot path behind NetworkManager-wait-online (5.5s) with no
  # containers on this laptop. Socket-activated, it starts on the first `docker`
  # command instead.
  virtualisation.docker.enableOnBoot = false;
  # Nothing here needs the network up before login (/data is an automount).
  systemd.services.NetworkManager-wait-online.enable = false;
  # No WWAN card fitted (`mmcli -L`: no modems).
  networking.modemmanager.enable = false;
  # systemd-boot menu: 2s instead of 5s; hold Space at power-on to pick a generation.
  boot.loader.timeout = 2;

  # Tdarr worker for the anime remux (server on Umaro). See modules/tdarr-node.nix.
  tdarrNode.enable = true;

  # GPU config lives in hardware-laptop.nix.

  system.stateVersion = "26.05";          # [cite: 120]
}