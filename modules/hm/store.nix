# render artifacts.store -> age.secrets
{
  pkgs,
  config,
  lib,
  ...
}:

{

  age.identityPaths = config.artifacts.config.agenix.identityPaths;
  age.secrets =
    let
      # todo : make this more readable, once we have written tests for it
      keyValues = lib.listToAttrs (
        lib.flatten (
          map (
            artifact:
            map (
              file:
              lib.nameValuePair "${artifact.name}-${file.name}" {
                file = "${config.artifacts.config.agenix.flakeStoreDir}/per-user/${config.artifacts.config.agenix.username}/${artifact.name}/${file.name}.age";
                inherit (file) path mode;
              }
            ) (lib.attrValues artifact.files)
          ) (lib.attrValues config.artifacts.store)
        )
      );
    in
    keyValues;

}
