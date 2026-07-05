{ pkgs, ... }:

{
  home.username = "jade";
  home.homeDirectory = "/home/jade";
  home.stateVersion = "26.05";

  # User specific native packages (CLI & Dev runtimes)
  home.packages = with pkgs; [
    firefox
    chromium
    soundwireserver
    python314
    libvlc
    easytag
    terraform
    awscli
    mpv
    libusb1
    widevine-cdm
  ];

  # Fully Declarative Git Config (Warning-free format)
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "jadesgit";
        email = "jadepropix@gmail.com";
      };
      credential = {
        helper = "store";
      };
    };
  };

  # Fully Declarative VS Code + Extensions (Warning-free format)
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs; [
        vscode-extensions.hashicorp.terraform
      ];
    };
  };
}