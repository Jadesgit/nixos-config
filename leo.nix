{ config, pkgs, lib, modulesPath, ... }:

# leo — small infra VM on proxmox2 (192.168.0.10). Named for General Leo, the
# "super soldier" version of the old soldier Umaro.
#
# Holds the services that must survive Umaro / the old Proxmox node dying:
# ntfy first, then Uptime Kuma, then the UniFi controller. NOT a media host.
# Built as a Proxmox VMA image (nixos-rebuild-free first boot), see
# proxmox repo `group_vars/all.yml` for the guest spec.

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
    ./modules/base.nix
  ];

  networking.hostName = "leo";

  # Static .11 — Caddy, Kuma notifications and the phone all point at it.
  networking.useDHCP = false;
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "192.168.0.11";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.0.1";
  # Technitium primary, Pi-hole secondary — same pair DHCP hands out.
  networking.nameservers = [ "192.168.0.2" "192.168.0.3" ];

  # ── Proxmox guest spec baked into the image ───────────────────────────────
  proxmox = {
    qemuConf = {
      name = "leo";
      cores = 2;
      memory = 3072;
      bios = "seabios";
      # Pinned MAC: the FortiGate caches ARP aggressively (see proxmox repo
      # CLAUDE.md), so never let this churn.
      net0 = "virtio=BC:24:11:1E:0E:11,bridge=vmbr0,firewall=0";
      additionalSpace = "4G";
    };
    qemuExtraConf = {
      onboot = 1;
      startup = "order=2";   # after Technitium (order=1)
      cpu = "host";          # default kvm64 hides AVX; MongoDB >=5 (UniFi) will not start without it
    };
    cloudInit.enable = false;   # network + keys are declared above, not injected
  };

  # ── Access: keys only ─────────────────────────────────────────────────────
  users.users.jade.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBmweOQyMSWVhPDwcNotPsiWPCmFG7bKS/6WqzuKevaJ jade@jades-Mac-mini"  # Gogo
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYZwrgpOLwG1I53Ylt2MODlaTQBj81vx/6G4QLMm3FmXlKX0/j2ZsY6m0D96CtH0dFerZbisD+dUFgqOZgITd5Gb9fW8Dkam5R8ytsaZxuCkAzTdFXJM/7D3Qu5Qojwm/H9QKhwoUfKwwwmRLUG9wzsnH4DlbDDIBmbll0SUsLPvzuJYa8O5KLhHk11eqYzBvt/yw0zcipAHFVmzI/cw7Ap8asr5e1ggeoVS2CKuwosXoxk7LJvhM2pnBjYeXTTPzk5/KFfjo/ZYINw0l/C9gDTLZvLEUqeMzVU3W/pIBDJKKeJHbZmcGgZusRuGuFv+BIouuvuFS7MwlLPZAJj/Z8iYpqKRta+FhNtocypbdEHFhSE3+NeNugCoNJWEg2eojH/1c7Y9isKUafw0zKKP+8Qc3muMEXfHbYCTdVmqDxzQ+zmB9AmXihGd+LeF+yG6nNf8VCuDPqhw1/9j4+LG6T+U5mW0FU8XBE8g82RGMsV6764dmBSRQJodB6B2oNxKkU/E8T8oOnsRD2o2vmg1A5VTW0pTcPpe7cYAqrGICaYQ4AG/O9IaToFO73VED34iytl5BIE+P526xpfyHRZsO8KscwO+9fA5kT8JTzZilLncYikSJB+4rc5BykbK6kWick88h54MeY2Km46QyejDjqS7qg+bjp/kZsTARpKnQL5Q== nixos-terra"  # Terra
  ];
  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.jade.openssh.authorizedKeys.keys;
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };
  # Key-only SSH + wheel sudo without a password: headless, LAN-only box that
  # Claude/Ansible must be able to administer non-interactively.
  security.sudo.wheelNeedsPassword = false;

  # ── Ports for the services that will land here ────────────────────────────
  # (Docker-published ports bypass this firewall anyway; listed for honesty.)
  networking.firewall.allowedTCPPorts = lib.mkAfter [ 8090 3001 8443 8080 ];
  networking.firewall.allowedUDPPorts = lib.mkAfter [ 3478 10001 ];

  virtualisation.docker.autoPrune = { enable = true; dates = "weekly"; };
  environment.systemPackages = with pkgs; [ git ];

  system.stateVersion = "26.05";
}
