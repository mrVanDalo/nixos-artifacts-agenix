{
  pkgs,
  inputs,
  ...
}:
with pkgs;
with lib;
{

  # todo : make sure this script is executed before everything else
  check_configuration = pkgs.writers.writeBash "agenix-check-config.sh" ''
    export PATH=${lib.makeBinPath [ pkgs.gojq ]}:$PATH

    if ! publicHostKey=$(gojq -e -r '.publicHostKey' "$config"); then
      echo "Error: Missing mandatory 'publicHostKey' field in config file"
      exit 1
    fi

    if [ -z "$publicHostKey" ]; then
      echo "Error: 'publicHostKey' value cannot be empty"
      exit 1
    fi


    exit 0
  '';

  check_serialization = pkgs.writers.writeBash "agenix-check.sh" ''
    # set -x

    store=$(gojq -r '.store // "secrets"' "$config")
    store="$(eval echo "$store")"


    for file in $(find "$inputs" -type f); do
      # Remove the $out prefix to get the relative path
      relative_path=''${file#$inputs/}

      if [[ -f "$store/per-machine/$machine/$artifact/$relative_path.age" ]]
      then
        echo " - ✅ $artifact/$relative_path"
      else
        echo " - ❌ $artifact/$relative_path"
        exit 1
      fi

    done

    exit 0
  '';

  # will be called on each artifact
  serialize = pkgs.writers.writeBash "agenix-serialize.sh" ''
    export PATH=${
      lib.makeBinPath [
        inputs.agenix.packages.${pkgs.system}.default
        pkgs.gojq
      ]
    }:$PATH
    #set -x

    export BACKUP=$(mktemp -d)
    export RULES=$(mktemp)

    store="$(gojq -r '.store // "secrets"' "$config")"
    store="$(eval echo "$store")"

    trap 'rm -rf "$RULES" "$BACKUP"' EXIT

    for file in $(find "$out" -type f); do
      # Remove the $out prefix to get the relative path
      relative_path=''${file#$out/}

      echo " - 🕛 $artifact/$relative_path"

      {
        echo "{"
        echo "  \"$store/per-machine/$machine/$artifact/$relative_path.age\".publicKeys = ["
        gojq -r '[.publicHostKey] + .publicUserKeys | .[] | "    \"" + . + "\""' $config
        echo "  ];"
        echo "}"
      } > $RULES

      if [[ -f "$store/per-machine/$machine/$artifact/$relative_path.age" ]]
      then
        rm -rf "$store/per-machine/$machine/$artifact/$relative_path.age"
      fi
      cat "$file" | agenix -e "$store/per-machine/$machine/$artifact/$relative_path.age"

      echo " - 💾 $artifact/$relative_path"

    done
  '';

  # skip deserialization (managed by agenix itself)
  deserialize = pkgs.writers.writeBash "agenix-deserialize.sh" ''
    exit 0
  '';

}
