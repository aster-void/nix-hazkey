{
  description = "fcitx5-hazkey packaged for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    packages = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      dictionary = import ./packages/dictionary {inherit pkgs;};
      fcitx5-hazkey = import ./packages/fcitx5-hazkey {inherit pkgs;};
      hazkey-server = import ./packages/hazkey-server {inherit pkgs;};
      hazkey-settings = import ./packages/hazkey-settings {inherit pkgs;};
      zenzai_v2 = import ./packages/zenzai_v2 {inherit pkgs;};
      zenzai_v3-small = import ./packages/zenzai_v3-small {inherit pkgs;};
      zenzai_v3_1-small = import ./packages/zenzai_v3_1-small {inherit pkgs;};
      zenzai_v3_1-xsmall = import ./packages/zenzai_v3_1-xsmall {inherit pkgs;};
    });

    nixosModules.hazkey = import ./modules/nixos/hazkey {flake = self;};
    homeModules.hazkey = import ./modules/home/hazkey {flake = self;};

    checks = forAllSystems (system: let
      pkgs = pkgsFor system;
      flake = self // {inherit inputs;};
    in {
      nixos-base = import ./checks/nixos-base.nix {inherit pkgs flake;};
      nixos-cpu = import ./checks/nixos-cpu.nix {inherit pkgs flake;};
      nixos-vulkan = import ./checks/nixos-vulkan.nix {inherit pkgs flake;};
      nixos-minimal = import ./checks/nixos-minimal.nix {inherit pkgs flake;};
      home-manager-basic = import ./checks/home-manager-basic.nix {inherit pkgs flake;};
      home-manager-vulkan = import ./checks/home-manager-vulkan.nix {inherit pkgs flake;};
      cross-nixos-hm = import ./checks/cross-nixos-hm.nix {inherit pkgs flake;};
    });

    devShells = forAllSystems (system: {
      default = import ./devshell.nix {pkgs = pkgsFor system;};
    });

    formatter = forAllSystems (system: (pkgsFor system).alejandra);
  };
}
