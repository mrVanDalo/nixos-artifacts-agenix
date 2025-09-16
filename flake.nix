{
  description = "agenix implementation of nixos-artifacts";

  inputs = {

    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";

    nixos-artifacts.url = "git+ssh://git@github.com/mrVanDalo/nixos-artifacts.git?ref=main";
    nixos-artifacts.inputs.nixpkgs.follows = "nixpkgs"; # only private input

    devshell.url = "github:numtide/devshell";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
          backends = import ./backend_agenix.nix {
            inherit pkgs inputs;
          };
        in
        {

          # provide all packages
          packages = {
            inherit (backends) check_serialization serialize deserialize;
          };

          packages.default = inputs.nixos-artifacts.packages.${system}.default.override {
            backends.agenix = { inherit (backends) check_serialization serialize deserialize; };
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
          imports = [
            ./modules
          ];
        };

        nixosConfigurations.machine-one-agenix = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.nixos-artifacts.nixosModules.default
            inputs.nixos-artifacts.nixosModules.examples
            (
              { pkgs, config, ... }:
              {
                networking.hostName = "machine-one-agenix";
                artifacts.default.backend.serialization = "agenix";
                artifacts.config.agenix.store = "$HOME/artifacts";
                artifacts.config.agenix.publicHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUXkewyZ94A7CeCyVvN0KCqPn+8x1BZaGWMAojlfCXO";
                artifacts.config.agenix.publicUserKeys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILE1jxUxvujFaj8kSjwJuNVRUinNuHsGeXUGVG6/lA1O"
                ];
              }
            )
          ];
        };

      };
    };
}
