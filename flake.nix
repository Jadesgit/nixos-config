outputs = { self, nixpkgs, home-manager, nix-flatpak, ... }@inputs: {
    nixosConfigurations = {
      
      # 🖥️ Desktop 
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./configuration.nix nix-flatpak.nixosModules.nix-flatpak ];
      };

      # 💻 Laptop
      laptop = nixpkgs.lib.nixosSystem {
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

    };
  };