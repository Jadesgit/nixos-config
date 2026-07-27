{ config, pkgs, ... }:

# Workstation profile — kept as a thin shim so terra and locke need no changes.
#
# The real content now lives in ./modules/. This split exists because umaro is
# a headless server: it imports modules/base.nix only, and must not inherit the
# desktop stack (KDE, pipewire, Bluetooth, Flatpak).
#
# Tailscale note: nixpkgs shipped tailscale 1.98.9 with a stale Go vendorHash,
# which fails its fixed-output derivation and takes the whole system build down.
# It is not in use, so it stays disabled until upstream corrects the hash.

{
  imports = [
    ./modules/base.nix
    ./modules/desktop.nix
    ./modules/nas-data.nix
  ];
}
