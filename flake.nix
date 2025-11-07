{
  description = "agenix implementation of nixos-artifacts";

  inputs = {
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    devshell.url = "github:numtide/devshell";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-artifacts.inputs.nixpkgs.follows = "nixpkgs"; # only private input
    nixos-artifacts.url = "github:mrVanDalo/nixos-artifacts/home-manager";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./nix/formatter.nix
        ./nix/devshells.nix
        ./nix/options.nix
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        {
          pkgs,
          self',
          system,
          ...
        }:
        let
          backends = import ./backend_agenix.nix { inherit pkgs inputs; };
        in
        {

          # provide all packages
          packages = {
            inherit (backends) check_serialization serialize deserialize;
          };
          packages.default = inputs.nixos-artifacts.packages.${system}.default.override {
            backends.agenix = { inherit (backends) check_serialization serialize deserialize; };
          };

          # just for testing
          packages.vmware = inputs.nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "vm-nogui";
            modules = [
              # todo : configure nixos
              # todo : configure home manager
            ];
          };

        };

      flake = {

        nixosModules.default = {
          imports = [
            inputs.agenix.nixosModules.default
            ./modules
          ];
        };

        nixosModules.without-agenix = {
          imports = [ ./modules ];
        };

        homeModules.default = {
          imports = [
            inputs.agenix.homeManagerModules.default
            ./modules/hm
          ];
        };

        homeModules.without-agenix = {
          imports = [ ./modules/hm ];
        };

        nixosConfigurations.machine-one-agenix = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            inputs.nixos-artifacts.nixosModules.default
            inputs.nixos-artifacts.nixosModules.examples
            (
              { pkgs, config, ... }:
              {
                networking.hostName = "machine-one-agenix";
                artifacts.default.backend.serialization = "agenix";
                artifacts.config.agenix.storeDir = "./secrets";
                artifacts.config.agenix.flakeStoreDir = ./secrets;
                artifacts.config.agenix.publicHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUXkewyZ94A7CeCyVvN0KCqPn+8x1BZaGWMAojlfCXO";
                artifacts.config.agenix.publicUserKeys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILE1jxUxvujFaj8kSjwJuNVRUinNuHsGeXUGVG6/lA1O"
                  "age1yubikey1q0adkk7m7770aaqer8khj578ffzpqcxp3uwdv69zhgsmuuf6afhygagnhgc" # age-plugin-yubikey --list
                ];
              }
            )
          ];
        };

        # todo : render options to documentation
        homeConfigurations.my-user = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            inputs.nixos-artifacts.homeModules.default
            inputs.nixos-artifacts.homeModules.examples
            self.homeModules.default
            (
              { pkgs, ... }:
              {
                home.stateVersion = "25.05";
                home.username = "some-test-name";
                home.homeDirectory = "/home/test";
                artifacts.default.backend.serialization = "agenix";
                artifacts.config.agenix.username = "my-user";
                artifacts.config.agenix.storeDir = "./secrets";
                artifacts.config.agenix.flakeStoreDir = ./secrets;
                artifacts.config.agenix.publicUserKeys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILE1jxUxvujFaj8kSjwJuNVRUinNuHsGeXUGVG6/lA1O"
                  "age1yubikey1q0adkk7m7770aaqer8khj578ffzpqcxp3uwdv69zhgsmuuf6afhygagnhgc" # age-plugin-yubikey --list
                ];
              }
            )
          ];
        };

      };
    };
}
