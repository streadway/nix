{
  config,
  inputs,
  ...
}:
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "sean";
    autoMigrate = true;
    taps = {
      "schpet/homebrew-tap" = inputs.schpet-tap;
    };
    mutableTaps = false;
  };

  homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
}
