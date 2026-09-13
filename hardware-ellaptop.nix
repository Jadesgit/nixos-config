# PLACEHOLDER — replace this whole file with the real output of
# `nixos-generate-config --root /mnt` run on the actual Dell 5501 during the
# physical install (see Part 2 of the Ellaptop plan). Disk UUIDs and detected
# kernel modules are hardware-specific and can't be written ahead of time.
# This file exists only so `ellaptop.nix`'s import list evaluates cleanly
# until then — do not install from this as-is.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000"; # TODO: real UUID from install
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0000-0000"; # TODO: real UUID from install
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
