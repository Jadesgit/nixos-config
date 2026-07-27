{ config, pkgs, lib, ... }:

# umaro — headless Docker host, VM on proxmox2 (192.168.0.10).
# Replaces the hand-built Ubuntu 22.04 VM. Runs the stacks from ~/git/compose.
#
# Imports modules/base.nix ONLY — no desktop stack.

{
  imports = [
    ./modules/base.nix
  ];

  networking.hostName = "umaro";

  # Static .30 — every jadeshomelab.website DNS record points here, so the
  # address must not move during the migration.
  networking.useDHCP = false;
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "192.168.0.30";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.0.1";
  # Pi-hole today; becomes the Technitium resolver after that migration.
  networking.nameservers = [ "192.168.0.3" ];

  # ── Intel Quick Sync (iGPU passed through from the host) ──────────────────
  # Plex and Jellyfin transcode via /dev/dri/renderD128.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver   # iHD — CoffeeLake UHD 630
      vpl-gpu-rt           # VPL runtime for newer QSV paths
      intel-compute-runtime
    ];
  };

  # CRITICAL: LinuxServer containers reach renderD128 by the *numeric* GID of
  # the render group. Ubuntu used 109; NixOS would otherwise pick its own and
  # hardware transcoding would silently fall back to CPU. Pin it so the compose
  # files stay portable across both hosts during the migration.
  users.groups.render.gid = 109;
  users.users.jade.extraGroups = [ "render" "video" ];

  # ── NAS media ─────────────────────────────────────────────────────────────
  # Mounted at /media/nas to match what the compose stacks already reference
  # ($PLEXPATH, $DOWNLOADS). Not /data like the workstations — standardising
  # those is a follow-up, not a mid-migration change.
  fileSystems."/media/nas" = {
    device = "192.168.0.4:/volume1/data";
    fsType = "nfs4";
    options = [
      "hard"                # media serving wants retries, not I/O errors
      "timeo=14"
      "retrans=2"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
    ];
  };

  # ── Scratch disk (second virtual disk on the old SATA SSD) ────────────────
  # Write-heavy, entirely disposable: transcodes, nzbget unpack, torrent
  # incomplete. `nofail` matters — if the aging SSD dies, the host must still
  # boot rather than dropping to emergency mode.
  fileSystems."/scratch" = {
    device = "/dev/disk/by-label/scratch";
    fsType = "ext4";
    options = [ "defaults" "nofail" "discard" ];
  };

  systemd.tmpfiles.rules = [
    "d /scratch/transcode/plex        0775 jade users -"
    "d /scratch/transcode/jellyfin    0775 jade users -"
    "d /scratch/nzbget/inter          0775 jade users -"
    "d /scratch/downloads/incomplete  0775 jade users -"
  ];

  # ── Docker host ───────────────────────────────────────────────────────────
  virtualisation.docker = {
    enable = true;
    autoPrune = { enable = true; dates = "weekly"; };
  };

  environment.systemPackages = with pkgs; [
    git                  # the compose repo is cloned and pulled here
    intel-gpu-tools      # intel_gpu_top — proves Quick Sync is actually working
    libva-utils          # vainfo
    nfs-utils
  ];

  # Headless: no display manager, and don't wait on network-online at boot.
  services.qemuGuest.enable = true;   # lets Proxmox see IP/shutdown cleanly

  system.stateVersion = "26.05";
}
