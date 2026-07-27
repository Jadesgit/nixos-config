{ config, lib, pkgs, modulesPath, ... }:

# Hardware profile for umaro — a QEMU/KVM guest on proxmox2.
#
# ⚠️ PLACEHOLDER: regenerate from the running VM after first boot with
#     nixos-generate-config --show-hardware-config
# and commit the result. The disk device paths below are the expected layout
# for the generated image, not yet verified against a live install.

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Root comes from the generated image's single virtio disk.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
