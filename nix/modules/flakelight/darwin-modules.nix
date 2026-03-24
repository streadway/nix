{
  config,
  lib,
  flakelight,
  moduleArgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkOption;
  inherit (lib.types) lazyAttrsOf;
  inherit (flakelight.types) module nullable optCallWith;
in
{
  options = {
    darwinModule = mkOption {
      type = nullable module;
      default = null;
    };

    darwinModules = mkOption {
      type = optCallWith moduleArgs (lazyAttrsOf module);
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.darwinModule != null) {
      darwinModules.default = config.darwinModule;
    })

    (mkIf (config.darwinModules != { }) {
      outputs = { inherit (config) darwinModules; };
    })
  ];
}
