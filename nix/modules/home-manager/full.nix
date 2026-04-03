{ ... }:
{
  imports = [
    ./base.nix
    ./input-remapper.nix
    ./aws.nix
    ./go.nix
    ./heroku.nix
    ./js.nix
    ./k8s.nix
    ./nix.nix
    ./py.nix
    ./rs.nix
    ./sh.nix
  ];
}
