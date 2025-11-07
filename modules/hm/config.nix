{ lib, config, ... }:
with lib;
with types;
{

  options.artifacts.config.agenix = {
    storeDir = mkOption {
      type = str;
      description = ''
        Path to the secrets store where agenix backend will serialize secrets to.
      '';

      default = "secrets";
      example = "$HOME/nixos-secrets";
    };
    flakeStoreDir = mkOption {
      type = path;
      description = ''
        Path reference where encrypted secrets are stored for agenix.
        This is used to to populate `age.secrets`.
      '';
      example = lib.literalExpression ''
        {
          flakeStoreDir = inputs.my-secrets;
          flakeStoreDir = ./secrets;
        };
      '';
    };
    username = mkOption {
      type = str;
      description = "name of this homeConfiguration.";
      default = config.home.username; # fixme not a good default
      defaultText = "config.networking.hostName";
    };
    identityPaths = mkOption {
      type = listOf str;
      description = "path to the identities to decrypt the secrets at runtime";
      example = [ "~/.ssh/id_ed25519" ];
    };
    publicUserKeys = mkOption {
      type = listOf str;
      description = "public key used to encrypt secrets for this host";
      default = [ ];
    };
  };

}
