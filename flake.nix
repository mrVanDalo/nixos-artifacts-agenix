{
  description = "Description for the project";

  inputs = {
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    devshell.url = "github:numtide/devshell";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-artifacts.inputs.nixpkgs.follows = "nixpkgs"; # only private input
    nixos-artifacts.url = "git+ssh://forgejo@git.ingolf-wagner.de:2222/palo/nixos-artifacts.git?ref=main";
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
        inputs.nixos-artifacts.flakeModules.default
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      flake = {

        nixosModules.default = {
          imports = [ ./modules ];
        };

        nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            self.nixosModules.default
            inputs.nixos-artifacts.nixosModules.default
            inputs.nixos-artifacts.nixosModules.examples
            inputs.agenix.nixosModules.default
            (
              { pkgs, config, ... }:
              {
                networking.hostName = "example";
                artifacts.default.backend = config.artifacts.backend.agenix;
                artifacts.config.agenix.storeDirAgain = ./secrets;
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
