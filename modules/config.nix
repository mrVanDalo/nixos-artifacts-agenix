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
    machineName = mkOption {
      type = str;
      description = "name of this machine";
      default = config.networking.hostName; # fixme not a good default
      defaultText = "config.networking.hostName";
    };
    publicHostKey = mkOption {
      type = str;
      description = ''
        public key used to encrypt secrets for this host
        can be found via `ssh-keyscan <host>`
      '';
    };
    publicUserKeys = mkOption {
      type = listOf str;
      description = "public key used to encrypt secrets for this host";
      default = [ ];
    };
  };

}
