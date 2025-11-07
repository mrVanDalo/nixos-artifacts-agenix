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

    case "$artifact_context" in
      homemanager)
        # In Home Manager context, we require:
        # - $username env var
        # - .publicUserKeys present and non-empty in config
        if [ -z "${"username:-"}" ]; then
          echo "Error: 'username' environment variable must be set when artifact_context=homemanager"
          exit 1
        fi

        if ! gojq -e '.publicUserKeys and (.publicUserKeys | type == "array") and (.publicUserKeys | length > 0)' "$config" >/dev/null; then
          echo "Error: Missing or empty 'publicUserKeys' array in config file for Home Manager context"
          exit 1
        fi
        ;;
      nixos)
        # In NixOS context, we require:
        # - $machine env var
        # - .publicHostKey present and non-empty
        if [ -z "${"machine:-"}" ]; then
          echo "Error: 'machine' environment variable must be set when artifact_context=nixos"
          exit 1
        fi

        if ! publicHostKey=$(gojq -e -r '.publicHostKey' "$config"); then
          echo "Error: Missing mandatory 'publicHostKey' field in config file for NixOS context"
          exit 1
        fi

        if [ -z "$publicHostKey" ]; then
          echo "Error: 'publicHostKey' value cannot be empty"
          exit 1
        fi
        ;;
      *)
        echo "Error: Unknown artifact_context='$artifact_context'. Expected 'nixos' or 'homemanager'"
        exit 1
        ;;
    esac

    exit 0
  '';

  check_serialization = pkgs.writers.writeBash "agenix-check.sh" ''
    # set -x

    store=$(gojq -r '.storeDir // "secrets"' "$config")
    store="$(eval echo "$store")"

    for file in $(find "$inputs" -type f); do
      # Remove the $inputs prefix to get the relative path
      relative_path=''${file#$inputs/}

      case "$artifact_context" in
        homemanager)
          target="$store/per-user/$username/$artifact/$relative_path.age"
          ;;
        nixos)
          target="$store/per-machine/$machine/$artifact/$relative_path.age"
          ;;
        *)
          echo "Error: Unknown artifact_context='$artifact_context'. Expected 'nixos' or 'homemanager'"
          exit 1
          ;;
      esac

      if [[ -f "$target" ]]
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

    store="$(gojq -r '.storeDir // "secrets"' "$config")"
    store="$(eval echo "$store")"

    trap 'rm -rf "$RULES" "$BACKUP"' EXIT

    for file in $(find "$out" -type f); do
      # Remove the $out prefix to get the relative path
      relative_path=''${file#$out/}

      echo " - 🕛 $artifact/$relative_path"

      case "$artifact_context" in
        homemanager)
          target="$store/per-user/$username/$artifact/$relative_path.age"
          # Build rules for Home Manager: only publicUserKeys exist
          {
            echo "{"
            echo "  \"$target\".armor = true;"
            echo "  \"$target\".publicKeys = ["
            gojq -r '.publicUserKeys[] | "    \"" + . + "\""' $config
            echo "  ];"
            echo "}"
          } > $RULES
          ;;
        nixos)
          target="$store/per-machine/$machine/$artifact/$relative_path.age"
          # Build rules for NixOS: host key + user keys
          {
            echo "{"
            echo "  \"$target\".armor = true;"
            echo "  \"$target\".publicKeys = ["
            gojq -r '[.publicHostKey] + (.publicUserKeys // []) | .[] | "    \"" + . + "\""' $config
            echo "  ];"
            echo "}"
          } > $RULES
          ;;
        *)
          echo "Error: Unknown artifact_context='$artifact_context'. Expected 'nixos' or 'homemanager'"
          exit 1
          ;;
      esac

      if [[ -f "$target" ]]
      then
        rm -rf "$target"
      fi
      cat "$file" | agenix -e "$target"

      echo " - 💾 $artifact/$relative_path"

    done
  '';

  # skip deserialization (managed by agenix itself)
  deserialize = pkgs.writers.writeBash "agenix-deserialize.sh" ''
    exit 0
  '';

}
