{
  pkgs,
  inputs,
  lib,
  ...
}:
{

  check_serialization = pkgs.writers.writeBash "agenix-check.sh" ''
    echo '$config'
    cat $config
    echo
    exit 1
  '';

  # will be called on each artifact
  serialize = pkgs.writers.writeBash "agenix-serialize.sh" ''
    export PATH=${
      lib.makeBinPath [
        inputs.agenix.packages.${pkgs.system}.default
        pkgs.gojq
      ]
    }:$PATH
    set -x

    HOST_KEY=$(cat $config | gojq -r '.publicHostKey')

    export RULES=$(mktemp)
    trap 'rm -f "$RULES"' EXIT
    
    for file in $(find "$out" -type f); do
        # Remove the $out prefix to get the relative path
        relative_path=''${file#$out/}
        echo "Serialize: $file"
        echo "Serialize: $relative_path"
        echo "{ \"secrets/per-machine/$machine/$artifact/$relative_path.age\".publicKeys = [ \"''${HOST_KEY}\" ]; }" > $RULES
        echo $RULES
        cat $RULES
        cat "$file" | agenix -e "secrets/per-machine/$machine/$artifact/$relative_path.age"
    done
  '';

  # skip deserialization (managed by agenix itself)
  deserialize = pkgs.writers.writeBash "agenix-deserialize.sh" ''
    exit 0
  '';

  #deserialize = pkgs.writers.writeBash "agenix-deserialize.sh" ''
  #  for file in $(find "$inputs" -type f); do
  #      # Remove the $input prefix to get the relative path
  #      relative_path=''${file#$inputs/}
  #      echo "Deserialize: $relative_path"
  #      #touch $out/$relative_path
  #  done
  #'';

}
