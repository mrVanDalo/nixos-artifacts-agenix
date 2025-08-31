{
  description = "Description for the project";

  inputs = {
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";

    nixos-artifacts.url = "path:///home/palo/dev/nixos/nixos-artifacts";
    nixos-artifacts.inputs.nixpkgs.follows = "nixpkgs"; # only private input
    #nixos-artifacts.url = "git+ssh://forgejo@git.ingolf-wagner.de:2222/palo/nixos-artifacts.git?ref=main";

    #private-parts.url =
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
        {
          packages.default = inputs.nixos-artifacts.packages.${system}.default.override {
            # todo : call it backends
            backend.agenix = import ./agenix.nix {
              inherit pkgs inputs;
              inherit (pkgs) lib;
            };
          };
        };
      flake = {

        nixosConfigurations.machine-one-agenix = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            inputs.nixos-artifacts.nixosModules.default
            inputs.nixos-artifacts.nixosModules.examples
            #inputs.agenix.nixosModules.default
            (
              { pkgs, config, ... }:
              {
                networking.hostName = "machine-one-agenix";
                artifacts.default.backend.serialization = "agenix";
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
