{
  description = "Jade's Multi-Machine NixOS Flake";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak, ... }@inputs: {
    nixosConfigurations = {

      # 🖥️ Desktop Target (Terra)
      terra = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix 
          nix-flatpak.nixosModules.nix-flatpak
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jade = import ./home-jade.nix;
          }
        ];
      };

      # 🐳 Docker host — VM on proxmox2. Headless, so no home-manager and no
      # nix-flatpak: it imports modules/base.nix only, never the desktop stack.
      umaro = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./umaro.nix
          ./hardware-umaro.nix
        ];
      };

      # 💻 Laptop Target (Locke)
      locke = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./laptop.nix
          nix-flatpak.nixosModules.nix-flatpak
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jade = import ./home-jade.nix;
          }
        ];
      };

      # 🦄 Laptop Target (Ellaptop) — Dell 5501, kid machine
      ellaptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./ellaptop.nix
          nix-flatpak.nixosModules.nix-flatpak
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jade = import ./home-jade.nix;
          }
        ];
      };

    };
  };
}