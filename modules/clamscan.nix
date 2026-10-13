{ config, lib, pkgs, ... }:

# Scheduled on-demand ClamAV scan (no resident clamd). Signatures via freshclam;
# results to /var/log/clamscan/last.log; ntfy on leo gets a push on a hit or an error.
# Enable per host: homelab.clamscan = { enable = true; paths = [ ... ]; };

let
  cfg = config.homelab.clamscan;

  # Video/audio/image/subtitle files can't realistically carry malware; skipping them
  # keeps a media-library scan to the executables, archives and documents.
  mediaExts = [ "mkv" "mp4" "m4v" "avi" "mov" "wmv" "ts" "webm" "mp3" "flac" "m4a" "m4b"
                "ogg" "opus" "wav" "aac" "jpg" "jpeg" "png" "webp" "gif" "srt" "sub" "idx" "nfo" "ass" ];
  mediaRegex = "\\.(${lib.concatMapStringsSep "|" (e: "${e}|${lib.toUpper e}") mediaExts})$";

  # Token for the write-only ntfy user `clamscan`; a missing file just means an unauthenticated (rejected) push.
  notify = title: priority: ''
    auth=(); [ -r ${cfg.ntfyTokenFile} ] && auth=(-H "Authorization: Bearer $(cat ${cfg.ntfyTokenFile})")
    ${pkgs.curl}/bin/curl -fsS -m 10 "''${auth[@]}" -H "Title: ${title}" -H "Priority: ${priority}" -H "Tags: biohazard" \
      --data-binary "$(grep -E 'FOUND|ERROR' "$LOG" | head -20; tail -9 "$LOG")" \
      ${cfg.ntfyUrl} || true
  '';
in
{
  options.homelab.clamscan = {
    enable = lib.mkEnableOption "scheduled ClamAV scan";
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/home/jade/Downloads" ];
    };
    skipMedia = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "Sun 03:00";
    };
    ntfyUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://192.168.0.11:8090/jadeshomelab-alerts";
    };
    ntfyTokenFile = lib.mkOption {
      type = lib.types.str;
      default = "/home/jade/.config/clamscan/ntfy-token";
    };
  };

  config = lib.mkIf cfg.enable {
    services.clamav.updater.enable = true;
    environment.systemPackages = [ pkgs.clamav ];

    systemd.services.clamscan = {
      description = "Scheduled ClamAV scan";
      after = [ "network-online.target" "clamav-freshclam.service" ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = cfg.paths;
      serviceConfig = {
        Type = "oneshot";
        User = "jade";
        LogsDirectory = "clamscan";
        Nice = 19;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
      };
      script = ''
        LOG=/var/log/clamscan/last.log
        set +e
        ${pkgs.clamav}/bin/clamscan -r -i --max-filesize=1000M --max-scansize=2000M \
          ${lib.optionalString cfg.skipMedia "--exclude=${lib.escapeShellArg mediaRegex}"} \
          --log="$LOG" ${lib.escapeShellArgs cfg.paths} > /dev/null
        rc=$?
        set -e
        if [ "$rc" -eq 1 ]; then
          ${notify "ClamAV: infected files on ${config.networking.hostName}" "high"}
        elif [ "$rc" -ge 2 ]; then
          ${notify "ClamAV: scan error on ${config.networking.hostName}" "default"}
        fi
        exit "$rc"
      '';
    };

    systemd.timers.clamscan = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };
  };
}
