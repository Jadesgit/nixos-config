# Tdarr worker node (the server runs on Umaro: compose repo `tdarr/`, :8265).
#
# The node remuxes/transcodes files from the NAS library. It gets its OWN NFS
# mount of /volume1/data/plex with `hard` semantics: the desktop's /data mount
# (modules/nas-data.nix) is `soft` with a 1.4s timeout, which is right for a
# file manager but can turn a NAS hiccup into an I/O error halfway through
# writing a multi-GB file. Inside the container the library is /media — the
# same path the server uses — so no Tdarr path translators are needed.
#
# /dev/dri is passed through so Quick Sync (UHD 620) can be used for real
# re-encodes later. The MX150 (GP108) has no NVENC, so it isn't passed in.
{ config, lib, pkgs, ... }:

let
  cfg = config.tdarrNode;
  version = "2.95.01";   # keep in step with the server in compose/tdarr
in
{
  options.tdarrNode = {
    enable = lib.mkEnableOption "a Tdarr worker node";
    serverIP = lib.mkOption { type = lib.types.str; default = "192.168.0.30"; };
    nodeName = lib.mkOption { type = lib.types.str; default = config.networking.hostName; };
  };

  config = lib.mkIf cfg.enable {
    # No idle timeout: work happens inside the container, so the host sees the
    # mount as idle and would unmount it (and stop the node) mid-encode.
    fileSystems."/srv/tdarr-media" = {
      device = "192.168.0.4:/volume1/data/plex";
      fsType = "nfs4";
      options = [ "hard" "noatime" "x-systemd.automount" "noauto" "nofail"
                  "x-systemd.mount-timeout=30s" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/tdarr-node/configs 0755 root root -"
      "d /var/lib/tdarr-node/logs 0755 root root -"
      "d /var/lib/tdarr-node/cache 0755 root root -"   # remux scratch space, local NVMe
    ];

    virtualisation.oci-containers = {
      backend = "docker";
      containers.tdarr-node = {
        image = "ghcr.io/haveagitgat/tdarr_node:${version}";
        environment = {
          TZ = "America/Denver";
          PUID = "1000";
          PGID = "100";
          UMASK_SET = "002";
          nodeName = cfg.nodeName;
          serverIP = cfg.serverIP;
          serverPort = "8266";
          serverURL = "http://${cfg.serverIP}:8266";
          inContainer = "true";
          ffmpegVersion = "7";
        };
        volumes = [
          "/srv/tdarr-media:/media"
          "/var/lib/tdarr-node/configs:/app/configs"
          "/var/lib/tdarr-node/logs:/app/logs"
          "/var/lib/tdarr-node/cache:/temp"
        ];
        extraOptions = [ "--device=/dev/dri:/dev/dri" ];
      };
    };

    # Mount the library before the container starts (triggers the automount).
    systemd.services.docker-tdarr-node.unitConfig.RequiresMountsFor = [ "/srv/tdarr-media" ];
  };
}
