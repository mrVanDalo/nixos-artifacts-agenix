{
  pkgs,
  inputs,
  ...
}:
with pkgs;
with lib;
{

  check_serialization = pkgs.writers.writeBash "agenix-check.sh" ''
    # set -x

    for file in $(find "$inputs" -type f); do
      # Remove the $out prefix to get the relative path
      relative_path=''${file#$inputs/}

      if [[ -f "secrets/per-machine/$machine/$artifact/$relative_path.age" ]]
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

    trap 'rm -rf "$RULES" "$BACKUP"' EXIT

    for file in $(find "$out" -type f); do
      # Remove the $out prefix to get the relative path
      relative_path=''${file#$out/}

      echo " - 🕛 $artifact/$relative_path"

      {
        echo "{"
        echo "  \"secrets/per-machine/$machine/$artifact/$relative_path.age\".publicKeys = ["
        gojq -r '[.publicHostKey] + .publicUserKeys | .[] | "    \"" + . + "\""' $config
        echo "  ];"
        echo "}"
      } > $RULES

      if [[ -f "secrets/per-machine/$machine/$artifact/$relative_path.age" ]]
      then
        mv -f "secrets/per-machine/$machine/$artifact/$relative_path.age" $BACKUP/file.age
        cat "$file" | agenix -e "secrets/per-machine/$machine/$artifact/$relative_path.age" || \
          mv $BACKUP/file.age "secrets/per-machine/$machine/$artifact/$relative_path.age"
      else
        cat "$file" | agenix -e "secrets/per-machine/$machine/$artifact/$relative_path.age"
      fi

      echo " - 💾 $artifact/$relative_path"

    done
  '';

  # skip deserialization (managed by agenix itself)
  deserialize = pkgs.writers.writeBash "agenix-deserialize.sh" ''
    exit 0
  '';

}
