{ lib, config, ... }:
with lib;
with types;
{

  options.artifacts.config.agenix = {
    storeDir = mkOption {
      type = str;
      description = "Path to the secrets store for agenix backend";
      default = "secrets";
    };
    # fixme should not be here multiple times
    storeDirAgain = mkOption {
      type = path;
      description = "Path to the secrets store for agenix backend";
    };
    machineName = mkOption {
      type = str;
      description = "name of this machine";
      default = config.networking.hostName; # fixme not a good default
    };
    publicHostKey = mkOption {
      type = str;
      description = "public key used to encrypt secrets for this host";
    };
    publicUserKeys = mkOption {
      type = listOf str;
      description = "public key used to encrypt secrets for this host";
      default = [ ];
    };
  };

}
