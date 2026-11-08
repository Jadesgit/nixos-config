# Locke — Lenovo ThinkPad T580 (8th-gen Intel Kaby Lake-R + NVIDIA MX150).
#
# Started life as nixos-generate-config output; the disk/boot block below is
# still that. Everything about the *hardware* (GPU, firmware, kernel modules)
# lives here; power/usage policy lives in laptop.nix.
#
# Also applied from flake.nix: nixos-hardware's lenovo-thinkpad-t480 profile,
# which brings Intel microcode + i915/VA-API, SSD fstrim, TrackPoint, TLP and
# `throttled` (fixes Lenovo's BD-PROCHOT/power-limit throttling on this
# generation — otherwise the CPU can sit near 1.6 GHz under load).
#
# If you ever re-run nixos-generate-config, copy only the fileSystems/swap
# UUIDs back in — don't overwrite this file.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # --- Kernel / initrd -------------------------------------------------------
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # --- Disks -----------------------------------------------------------------
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a09963e1-869f-4c09-a355-36e96290fe3e";
      fsType = "ext4";
      options = [ "noatime" ];          # fewer SSD writes; nothing here needs atime
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/3A62-ED25";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/9c7fad4f-61bc-40f0-8001-4b3f21d6d950"; }
    ];

  # --- Firmware --------------------------------------------------------------
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;   # Intel Wi-Fi, i915 GuC/HuC, Bluetooth
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  services.fwupd.enable = true;                    # Lenovo ships T580 BIOS/EC/Thunderbolt updates via LVFS

  # --- Graphics: Intel UHD 620 (display) + NVIDIA MX150 (PRIME offload) -------
  # The Intel GPU drives the panel; the MX150 sleeps until a program is started
  # with `nvidia-offload <cmd>` (e.g. Dolphin, Steam games).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;                            # Steam/Wine 32-bit GL on the dGPU
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # Pascal (MX150) was dropped after the 580 branch: with `stable` (595.x) the
    # kernel logs "No NVIDIA GPU found" and the dGPU is dead. Pin legacy_580.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    modesetting.enable = true;
    # Saves VRAM across suspend so resume doesn't corrupt the desktop.
    powerManagement.enable = true;
    # finegrained (RTD3) needs Turing or newer — the MX150 is Pascal, leave off.
    powerManagement.finegrained = false;
    open = false;                                  # Pascal: the open kernel module doesn't support it
    nvidiaSettings = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Verify on the machine: lspci -D | grep -Ei 'vga|3d'
      # (0000:00:02.0 → PCI:0:2:0). The MX150's bus number varies by board.
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0";
    };
  };
}
