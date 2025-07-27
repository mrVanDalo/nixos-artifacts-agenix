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
                file = "${config.artifacts.config.agenix.storeDirAgain}/per-machine/${config.artifacts.config.agenix.machineName}/${artifact.name}/${file.name}.age";
              }
            ) (lib.attrValues artifact.files)
          ) (lib.attrValues config.artifacts.store)
        )
      );
    in
    keyValues;

}
