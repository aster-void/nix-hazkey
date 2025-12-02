{
  pkgs,
  inputs,
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
in {
  formatting = treefmtEval.config.build.check;
}
