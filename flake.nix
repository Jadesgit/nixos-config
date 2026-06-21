{
  description = "Jade's Multi-Machine NixOS Flake";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # 🌟 Add the Antigravity community flake input
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = { self, nixpkgs, antigravity-nix, home-manager, nix-flatpak, ... }@inputs: {
    nixosConfigurations = {
      
      # 🖥️ Desktop Target
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit antigravity-nix; };
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

      # 💻 Laptop Target
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit antigravity-nix; };
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

    };
  };
}