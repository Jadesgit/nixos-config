{ pkgs, ... }:

# Ellaptop-only: creative/educational apps, a retro emulation suite, Android
# app support via Waydroid, and phone-as-drawing-tablet tooling. Kept out of
# modules/desktop.nix so terra/locke don't inherit any of it.

{
  virtualisation.waydroid.enable = true;

  environment.systemPackages = with pkgs; [
    # Creative / educational
    tuxpaint
    krita
    gcompris

    # Web (Clever, iReady, library digital resources are all browser-based)
    firefox
    chromium

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
    # TODO: add a "Library" desktop item once we know the actual library
    # system/card provider — don't want to guess the URL.
  ];
}
