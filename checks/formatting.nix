{
  pkgs,
  flake,
  ...
}: let
  treefmtEval = flake.lib.lazyInputs.treefmt-nix.lib.evalModule pkgs ../treefmt.nix;
in
  treefmtEval.config.build.check flake
