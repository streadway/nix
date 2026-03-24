{
  config,
  lib,
  inputs,
  flakelight,
  moduleArgs,
  ...
}:
let
  inherit (builtins) mapAttrs;
  inherit (lib)
    foldl
    mapAttrsToList
    mkIf
    mkOption
    recursiveUpdate
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (flakelight) selectAttr;
  inherit (flakelight.types) optCallWith;

  # Avoid checking if the top-level is a derivation, which forces module evaluation.
  isDeriv = x: x ? config.system.build.toplevel;

  mkDarwin =
    hostname: cfg:
    inputs.nix-darwin.lib.darwinSystem (
      cfg
      // {
        specialArgs = {
          inherit inputs hostname;
          inputs' = mapAttrs (_: selectAttr cfg.system) inputs;
        }
        // (cfg.specialArgs or { });
        modules = [ config.propagationModule ] ++ (cfg.modules or [ ]);
      }
    );

  configs = mapAttrs (
    hostname: cfg: if isDeriv cfg then cfg else mkDarwin hostname cfg
  ) config.darwinConfigurations;
in
{
  options.darwinConfigurations = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
    default = { };
  };

  config.outputs = mkIf (config.darwinConfigurations != { }) {
    darwinConfigurations = configs;
    checks = foldl recursiveUpdate { } (
      mapAttrsToList (name: value: {
        ${value.config.nixpkgs.system}."darwin-${name}" =
          value.pkgs.runCommand "check-darwin-${name}" { }
            "echo ${value.config.system.build.toplevel} > $out";
      }) configs
    );
  };
}
