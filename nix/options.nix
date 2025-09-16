{ self, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      system,
      ...
    }:
    let
      optionsTemplate = pkgs.writeText "options.mustache" ''
        = Options

        {{#options}}
        == {{name}}{{^hasDefault}} (mandatory) {{/hasDefault}}
        [horizontal]
        Name::
        `{{prefix}}.name`
        {{#description}}Description::
        {{description}}
        {{/description}}
        Type::
        `{{type}}`
        {{#defaultText}}
        Default::
        `{{defaultText}}`
        {{/defaultText}}
        {{#example}}
        [vertical]
        Example::
        +
        [source,nix]
        ----
        {{example}}
        ----
        {{/example}}

        {{/options}}
      '';
    in
    {

      packages = {

        # JSON dump of option definitions (types, descriptions, etc.)
        eval-options-json = pkgs.writeText "eval-options.json" (
          builtins.toJSON (
            let
              res = pkgs.lib.evalModules { modules = [ "${self}/modules/config.nix" ]; };
              opts = res.options.artifacts.config.agenix;
            in
            builtins.mapAttrs (name: opt: {
              type = if (opt ? type && opt.type ? name) then opt.type.name else null;
              description = if (opt ? description) then opt.description else null;
              hasDefault = opt ? default;
              defaultText =
                if opt ? defaultText then
                  if
                    builtins.isAttrs opt.defaultText
                    && opt.defaultText ? _type
                    && opt.defaultText._type == "literalExpression"
                  then
                    opt.defaultText.text
                  else if
                    builtins.isString opt.defaultText
                    || builtins.isBool opt.defaultText
                    || builtins.isInt opt.defaultText
                    || builtins.isFloat opt.defaultText
                  then
                    opt.defaultText
                  else
                    (builtins.fromJSON (builtins.toJSON opt.defaultText))
                else if opt ? default then
                  let
                    d = builtins.tryEval opt.default;
                  in
                  if d.success then
                    if builtins.isAttrs d.value && d.value ? _type && d.value._type == "literalExpression" then
                      d.value.text
                    else if builtins.isString d.value then
                      d.value
                    else if builtins.isBool d.value || builtins.isInt d.value || builtins.isFloat d.value then
                      builtins.toJSON d.value
                    else if builtins.isPath d.value then
                      builtins.toString d.value
                    else
                      (
                        let
                          j = builtins.tryEval (builtins.toJSON d.value);
                        in
                        if j.success then j.value else null
                      )
                  else
                    null
                else
                  null;
              example =
                if opt ? example then
                  if
                    builtins.isAttrs opt.example && opt.example ? _type && opt.example._type == "literalExpression"
                  then
                    opt.example.text
                  else if
                    builtins.isString opt.example
                    || builtins.isBool opt.example
                    || builtins.isInt opt.example
                    || builtins.isFloat opt.example
                  then
                    opt.example
                  else
                    (builtins.fromJSON (builtins.toJSON opt.example))
                else
                  null;
            }) opts
          )
        );
      };

      apps.eval-options-json = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "eval-options-json";
            runtimeInputs = [ pkgs.coreutils ];
            text = "cat ${self'.packages.eval-options-json}";
          }
        }/bin/eval-options-json";
      };

      apps.render-options-adoc = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "render-options-adoc";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.jq
              pkgs.mustache-go
            ];
            text = ''
              tmp=$(mktemp)
              jq 'to_entries | {prefix: "artifacts.config.agenix", options: (map({name: .key} + .value))}' ${self'.packages.eval-options-json} > "$tmp"
              mustache "$tmp" ${optionsTemplate}
              rm -f "$tmp"
            '';
          }
        }/bin/render-options-adoc";
      };

    };

}
