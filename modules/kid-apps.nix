{ pkgs, ... }:

# Ellaptop-only: creative/educational apps, Android app support via Waydroid,
# and phone-as-drawing-tablet tooling. The retro emulation suite itself now
# lives in ./emulation.nix (shared with locke — see laptop.nix) since locke's
# discrete GPU runs Dolphin far better than ellaptop's Intel UHD 630 can.

{
  imports = [ ./emulation.nix ];

  emulation = {
    enable = true;
    user = "ella";
  };

  virtualisation.waydroid.enable = true;

  # Single organized "click here for everything" page instead of ~100
  # individual desktop icons — the full Nebo School District educational
  # resource list plus the Spanish Fork library card resources, filtered to
  # what she'd actually click herself (teacher-only tools like quiz-creation
  # dashboards and staff docs are left off).
  environment.etc."ellaptop/learning-resources.html".source = ./assets/learning-resources.html;

  systemd.tmpfiles.rules =
    [
      # ella auto-logs in, so SDDM never passes a real password through PAM
      # for kwallet-pam to auto-unlock the wallet with — it ends up locked
      # and prompts on first use (e.g. saving a wifi password). Disable it
      # outright rather than fight that; nothing on this account needs
      # wallet-grade secret storage. copy-if-missing, so a manual re-enable
      # via System Settings survives future rebuilds.
      "d /home/ella/.config 0755 ella users -"
      "C /home/ella/.config/kwalletrc 0644 ella users - ${pkgs.writeText "kwalletrc" ''
        [Wallet]
        Enabled=false
      ''}"
    ];

  environment.systemPackages = with pkgs; [
    # Creative / educational
    tuxpaint
    krita
    gcompris

    # Web (Clever, iReady, library digital resources are all browser-based)
    firefox
    chromium
    google-chrome

    # Retro emulation suite (RetroArch cores, Dolphin, Pegasus launcher) is
    # provided by ./emulation.nix, imported above.

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
      name = "learning-resources";
      desktopName = "Learning Resources";
      comment = "All of Nebo School District's approved links + the library, organized in one page";
      exec = "firefox /etc/ellaptop/learning-resources.html";
      icon = "firefox";
    })
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
