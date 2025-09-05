# render artifacts.store -> age.secrets
{
  pkgs,
  config,
  lib,
  ...
}:

{

  age.secrets =
    let
      # todo : make this more readable, onc we have written tests for it
      keyValues = lib.listToAttrs (
        lib.flatten (
          map (
            artifact:
            map (
              file:
              lib.nameValuePair "${artifact.name}-${file.name}" {
                # fixme : config.networking.hostName might not be correct
                file = "${config.artifacts.config.agenix.flakeStoreDir}/per-machine/${config.artifacts.config.agenix.machineName}/${artifact.name}/${file.name}.age";
                inherit (file) owner group path;
              }
            ) (lib.attrValues artifact.files)
          ) (lib.attrValues config.artifacts.store)
        )
      );
    in
    keyValues;

}
