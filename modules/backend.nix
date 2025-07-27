{
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with types;
{

  # folder structure
  # ----------------
  #
  # $out/shared/<artifact-name>/<file-name>
  # $out/machines/<machine-name>/<artifact-name>/<file-name>
  #
  # $input/shared/<artifact-name>/<file-name>
  # $input/machines/<machine-name>/<artifact-name>/<file-name>
  #
  #
  # deserialization:
  # ----------------
  # $input -> program -> $out
  #
  # serialization:
  # --------------
  # $out -> program

  artifacts.backend.agenix = {
    # will be called on each artifact
    serialize = pkgs.writers.writeBash "serialize-with-artifacts" ''
      export PATH=${
        lib.makeBinPath [
          inputs.agenix.packages.${pkgs.system}.default
        ]
      }:$PATH
      for file in $(find "$out" -type f); do
          # Remove the $out prefix to get the relative path
          relative_path=''${file#$out/}
          echo "Serialize: $file"
          echo "Serialize: $relative_path"
          cat "$file" | agenix -e "secrets/per-machine/$machine/$artifact/$relative_path.age"
      done
    '';

    # skip deserialization (managed by agenix itself)
    deserialize = pkgs.writers.writeBash "deserialize-with-passage" ''
      export PATH=${lib.makeBinPath [ ]}:$PATH
      for file in $(find "$input" -type f); do
          # Remove the $input prefix to get the relative path
          relative_path=''${file#$input/}
          echo "Deserialize: $relative_path"
          #touch $out/$relative_path
      done
    '';
  };

}
