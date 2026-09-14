{ pkgs, ... }:

# Ellaptop-only: creative/educational apps, a retro emulation suite, Android
# app support via Waydroid, and phone-as-drawing-tablet tooling. Kept out of
# modules/desktop.nix so terra/locke don't inherit any of it.

let
  romsDir = "/home/ella/Games/roms";

  # Pegasus Frontend collections: one metadata.pegasus.txt per system, so she
  # gets a single "pick a game and play" launcher instead of RetroArch's raw
  # menu. Launch commands use each core's own standalone `retroarch-<core>`
  # wrapper binary (pkgs.libretro.<x>.meta.mainProgram — verified per-core,
  # not guessed) rather than hand-built `-L core.so` invocations.
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
  virtualisation.waydroid.enable = true;

  # Seed Pegasus's system-wide default game directory list (copied into
  # ~/.config/pegasus-frontend/game_dirs.txt on her first launch) and
  # pre-create the ROM folder tree with a starter metadata.pegasus.txt per
  # system. Uses tmpfiles `C` (copy-if-missing) rather than `C+`, so once
  # she/you hand-edit a metadata file to add real games, a rebuild won't
  # clobber it.
  environment.etc."xdg/pegasus-frontend/game_dirs.txt".text = "${romsDir}\n";

  systemd.tmpfiles.rules =
    [ "d ${romsDir} 0755 ella users -" ]
    ++ map (s: "d ${romsDir}/${s.name} 0755 ella users -") emuSystems
    ++ map (s: "C ${romsDir}/${s.name}/metadata.pegasus.txt 0644 ella users - ${emuMetaFile s}") emuSystems;

  environment.systemPackages = with pkgs; [
    # Creative / educational
    tuxpaint
    krita
    gcompris

    # Web (Clever, iReady, library digital resources are all browser-based)
    firefox
    chromium
    google-chrome

    # Retro emulation — NES through GameCube/Wii + handhelds. Covers most of
    # the mainline Zelda catalog: LoZ/Zelda II (NES, fceumm), A Link to the
    # Past (SNES, snes9x), Ocarina of Time/Majora's Mask (N64, mupen64plus),
    # Link's Awakening DX (GBC, gambatte), Minish Cap (GBA, mgba), Phantom
    # Hourglass/Spirit Tracks (DS, melonds); Wind Waker/Twilight Princess/
    # Skyward Sword/Four Swords Adventures via standalone dolphin-emu below.
    # ROMs must come from cartridges/discs you own — not something to source
    # here.
    (retroarch.withCores (cores: with cores; [ fceumm snes9x mupen64plus gambatte mgba melonds ]))
    dolphin-emu

    # Unified "pick a game and play" launcher fronting the cores/dolphin-emu
    # above (see emuSystems/game_dirs.txt below) — much friendlier than
    # RetroArch's own menu for a 3rd grader.
    pegasus-frontend

    # Phone as a drawing tablet: gfxtablet (uinput driver, pairs with the
    # GfxTablet Android app on the LG V40 for real pressure-sensitive input)
    # and weylus (browser-based fallback, works from the iPhone 12 too, no
    # pressure but fine for TuxPaint-style finger drawing).
    gfxtablet
    weylus

    # Music
    musescore
    lmms
    hydrogen
    qjackctl

    (makeDesktopItem {
      name = "clever";
      desktopName = "Clever";
      exec = "firefox https://clever.com";
      icon = "firefox";
    })
    (makeDesktopItem {
      name = "iready";
      desktopName = "iReady";
      exec = "firefox https://login.i-ready.com";
      icon = "firefox";
    })
    (makeDesktopItem {
      name = "library";
      desktopName = "Library";
      # Utah's Online School Library (UEN) — the modern name for what Nebo
      # School District still refers to as "Pioneer Library".
      exec = "firefox https://onlinelibrary.uen.org/";
      icon = "firefox";
    })
  ];
}
