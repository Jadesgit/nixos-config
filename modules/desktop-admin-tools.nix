{ pkgs, ... }:

# Admin/power-user utilities on top of modules/desktop.nix's base KDE stack.
# Imported explicitly by terra and locke, NOT by ellaptop (kid machine, kept
# simpler on purpose — see modules/kid-apps.nix instead).

{
  environment.systemPackages = with pkgs; [
    gparted krename
    kdePackages.isoimagewriter kdePackages.ksystemlog
  ];
}
