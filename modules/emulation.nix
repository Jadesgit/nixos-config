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
  emuSystems = [
    { name = "nes";  title = "Nintendo Entertainment System"; exts = "nes, zip";
      launch = "${pkgs.libretro.fceumm}/bin/retroarch-fceumm \"{file.path}\""; }
    { name = "snes"; title = "Super Nintendo Entertainment System"; exts = "smc, sfc, zip";
      launch = "${pkgs.libretro.snes9x}/bin/retroarch-snes9x \"{file.path}\""; }
    { name = "n64";  title = "Nintendo 64"; exts = "n64, z64, zip";
      launch = "${pkgs.libretro.mupen64plus}/bin/retroarch-mupen64plus-next \"{file.path}\""; }
    { name = "gbc";  title = "Game Boy Color"; exts = "gb, gbc, zip";
      launch = "${pkgs.libretro.gambatte}/bin/retroarch-gambatte \"{file.path}\""; }
    { name = "gba";  title = "Game Boy Advance"; exts = "gba, zip";
      launch = "${pkgs.libretro.mgba}/bin/retroarch-mgba \"{file.path}\""; }
    { name = "nds";  title = "Nintendo DS"; exts = "nds, zip";
      launch = "${pkgs.libretro.melonds}/bin/retroarch-melonds \"{file.path}\""; }
    { name = "gc";   title = "GameCube / Wii"; exts = "iso, rvz, gcm, wbfs";
      # dolphin-emu: -b/--batch exits Dolphin when emulation ends, -e/--exec
      # loads the given file — standard, long-stable Dolphin CLI syntax.
      launch = "${pkgs.dolphin-emu}/bin/dolphin-emu -b -e \"{file.path}\""; }
  ];

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
    environment.etc."xdg/pegasus-frontend/game_dirs.txt".text = "${cfg.romsDir}\n";

    systemd.tmpfiles.rules =
      [ "d ${cfg.romsDir} 0755 ${cfg.user} users -" ]
      ++ map (s: "d ${cfg.romsDir}/${s.name} 0755 ${cfg.user} users -") emuSystems
      ++ map (s: "C ${cfg.romsDir}/${s.name}/metadata.pegasus.txt 0644 ${cfg.user} users - ${emuMetaFile s}") emuSystems;
  };
}
