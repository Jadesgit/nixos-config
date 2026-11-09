{ config, lib, pkgs, ... }:

# Shared retro-emulation suite: RetroArch cores + standalone Dolphin, fronted
# by Pegasus Frontend as a single "pick a game and play" launcher. Factored
# out of kid-apps.nix (ellaptop-only) so locke can carry the exact same
# systems/cores — locke's discrete MX150 handles GameCube/Wii (Dolphin) far
# better than ellaptop's Intel UHD 630 can. Parameterized per-user so each
# host points it at its own account and ROMs directory.

let
  cfg = config.emulation;

  # One metadata.pegasus.txt per system, so the user gets a single launcher
  # instead of RetroArch's raw menu. Launch commands use each core's own
  # standalone `retroarch-<core>` wrapper binary (pkgs.libretro.<x>.meta.mainProgram
  # — verified per-core, not guessed) rather than hand-built `-L core.so` invocations.
  # --- Gamepad profiles ------------------------------------------------------
  # The iNNEXT SNES-style USB pad is a generic DragonRise chip (0079:0011,
  # name "USB Gamepad "). Four stock RetroArch profiles claim that same id, and
  # RetroArch picked "Retrolink Sega Saturn": Start on the pad's Select, no
  # Select at all, A/B and L/R swapped (Zelda's title/name screen unusable,
  # locke 2026-11-08). So: the stock profile set minus every profile claiming
  # 0079:0011, plus one measured from the real pad (evdev button indices:
  # X=0 A=1 B=2 Y=3 L=4 R=5 Select=8 Start=9, D-pad = axes 0/1).
  innextProfile = pkgs.writeText "iNNEXT-SNES-USB-Gamepad.cfg" ''
    input_driver = "udev"
    input_device = "USB Gamepad "
    input_device_display_name = "iNNEXT SNES-style USB Gamepad"
    input_vendor_id = "121"
    input_product_id = "17"
    input_x_btn = "0"
    input_a_btn = "1"
    input_b_btn = "2"
    input_y_btn = "3"
    input_l_btn = "4"
    input_r_btn = "5"
    input_select_btn = "8"
    input_start_btn = "9"
    input_up_axis = "-1"
    input_down_axis = "+1"
    input_left_axis = "-0"
    input_right_axis = "+0"
  '';
  autoconfigDir = pkgs.runCommand "retroarch-autoconfig-local" { } ''
    cp -r ${pkgs.retroarch-joypad-autoconfig}/share/libretro/autoconfig $out
    chmod -R u+w $out
    for f in $out/udev/*.cfg; do
      if grep -q '^input_vendor_id = "121"' "$f" && grep -q '^input_product_id = "17"' "$f"; then
        rm "$f"
      fi
    done
    cp ${innextProfile} $out/udev/iNNEXT-SNES-USB-Gamepad.cfg
  '';
  # Appended to every RetroArch launch from Pegasus. Start+Select opens the
  # RetroArch menu (save states, Quit) — there is no keyboard on the couch.
  raExtraCfg = pkgs.writeText "retroarch-emulation.cfg" ''
    joypad_autoconfig_dir = "${autoconfigDir}"
    input_menu_toggle_gamepad_combo = "4"
  '';
  ra = core: bin: "${core}/bin/${bin} --appendconfig ${raExtraCfg} \"{file.path}\"";

  emuSystems = [
    { name = "nes";  title = "Nintendo Entertainment System"; exts = "nes, NES, zip";
      launch = ra pkgs.libretro.fceumm "retroarch-fceumm"; }
    { name = "snes"; title = "Super Nintendo Entertainment System"; exts = "smc, sfc, zip";
      launch = ra pkgs.libretro.snes9x "retroarch-snes9x"; }
    { name = "n64";  title = "Nintendo 64"; exts = "n64, z64, zip";
      launch = ra pkgs.libretro.mupen64plus "retroarch-mupen64plus-next"; }
    { name = "gbc";  title = "Game Boy Color"; exts = "gb, gbc, zip";
      launch = ra pkgs.libretro.gambatte "retroarch-gambatte"; }
    { name = "gba";  title = "Game Boy Advance"; exts = "gba, zip";
      launch = ra pkgs.libretro.mgba "retroarch-mgba"; }
    { name = "nds";  title = "Nintendo DS"; exts = "nds, zip";
      launch = ra pkgs.libretro.melonds "retroarch-melonds"; }
    { name = "gc";   title = "GameCube / Wii"; exts = "iso, rvz, gcm, wbfs";
      # dolphin-emu: -b/--batch exits Dolphin when emulation ends, -e/--exec
      # loads the given file — standard, long-stable Dolphin CLI syntax.
      launch = "${pkgs.dolphin-emu}/bin/dolphin-emu -b -e \"{file.path}\""; }
  ];

  gameDirs = lib.concatMapStrings (s: "${cfg.romsDir}/${s.name}\n") emuSystems;

  emuMetaFile = s: pkgs.writeText "metadata-${s.name}.pegasus.txt" ''
    collection: ${s.title}
    shortname: ${s.name}
    extensions: ${s.exts}
    launch: ${s.launch}
  '';
in
{
  options.emulation = {
    enable = lib.mkEnableOption "the shared RetroArch/Dolphin/Pegasus emulation suite";

    user = lib.mkOption {
      type = lib.types.str;
      description = "Account that owns the ROMs directory and runs Pegasus.";
    };

    romsDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/${cfg.user}/Games/roms";
      defaultText = lib.literalExpression ''"/home/''${config.emulation.user}/Games/roms"'';
      description = "Root of the per-system ROM folder tree.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # NES through GameCube/Wii + handhelds.
      # ROMs must come from cartridges/discs you own — not something to source here.
      (retroarch.withCores (cores: with cores; [ fceumm snes9x mupen64plus gambatte mgba melonds ]))
      dolphin-emu
      pegasus-frontend
    ];

    # Seed Pegasus's system-wide default game directory list (copied into
    # ~/.config/pegasus-frontend/game_dirs.txt on first launch) and pre-create
    # the ROM folder tree with a starter metadata.pegasus.txt per system. Uses
    # tmpfiles `C` (copy-if-missing) rather than `C+`, so once a real
    # metadata file is hand-edited to add real games, a rebuild won't clobber it.
    # Pegasus only reads ~/.config/pegasus-frontend/game_dirs.txt — the /etc/xdg
    # copy was never picked up ("No metadata files found", locke 2026-11-08) —
    # so the per-user file is seeded too (C = only if missing; hand edits stay).
    # Pegasus does NOT recurse: each listed dir must hold a metadata file, so
    # list every system folder, not the roms root.
    environment.etc."xdg/pegasus-frontend/game_dirs.txt".text = gameDirs;

    # The parent (~/Games) is listed first: otherwise tmpfiles creates it
    # implicitly as root:root, and then refuses to fix ownership below it
    # (an "unsafe path transition" from a user dir into a root one). Seen on
    # locke 2026-11-08: ~/Games and the whole roms tree ended up root-owned.
    systemd.tmpfiles.rules =
      [ "d ${builtins.dirOf cfg.romsDir} 0755 ${cfg.user} users -"
        "d ${cfg.romsDir} 0755 ${cfg.user} users -" ]
      ++ map (s: "d ${cfg.romsDir}/${s.name} 0755 ${cfg.user} users -") emuSystems
      # L+ (symlink, replaced each switch), not C: the launch lines hold /nix/store
      # paths, so a copied file went stale on every update (and its paths could
      # be garbage-collected). Pegasus finds games by extension; nothing to hand-edit.
      ++ map (s: "L+ ${cfg.romsDir}/${s.name}/metadata.pegasus.txt - - - - ${emuMetaFile s}") emuSystems
      ++ [ "d /home/${cfg.user}/.config 0755 ${cfg.user} users -"
           "d /home/${cfg.user}/.config/pegasus-frontend 0755 ${cfg.user} users -"
           "C /home/${cfg.user}/.config/pegasus-frontend/game_dirs.txt 0644 ${cfg.user} users - ${pkgs.writeText "pegasus-game-dirs.txt" gameDirs}" ];
  };
}
