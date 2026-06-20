{ pkgs, ... }:

{
  home.username = "jade";
  home.homeDirectory = "/home/jade";
  home.stateVersion = "26.05"; # Home manager tracking version

  # User specific native packages (CLI & Dev runtimes)
  home.packages = with pkgs; [
    firefox
    soundwireserver
    python314
    libvlc
    easytag
    terraform
    awscli
    mpv
    libusb1
  ];

  # Fully Declarative Git Config (Your profile)
  programs.git = {
    enable = true;
    userName = "jadesgit";
    userEmail = "jadepropix@gmail.com";
  };

  # Fully Declarative VS Code + Extensions
  programs.vscode = {
    enable = true;
    extensions = with pkgs; [
      vscode-extensions.hashicorp.terraform
    ];
  };
}