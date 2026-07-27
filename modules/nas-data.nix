{ config, pkgs, ... }:

# Shared NAS NFS mount at /data (automounts on demand).
# umaro deliberately does NOT import this — it mounts the same export at
# /media/nas to match what the compose stacks already expect. Standardising
# the two mountpoints is a follow-up, not something to change mid-migration.

{
  fileSystems."/data" = {
    device = "192.168.0.4:/volume1/data";
    fsType = "nfs4";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "x-gvfs-hide"

      # 🛡️ The Kernel-Level Network Guardrails:
      "soft"        # Fail and return an I/O error instead of blocking indefinitely
      "timeo=14"    # Wait exactly 1.4 seconds before a retry (measured in tenths of a sec)
      "retrans=2"   # Retry only twice before giving up completely
    ];
  };
}
