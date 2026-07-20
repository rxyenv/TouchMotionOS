{
  description = "TOMORO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    os.url = "./os";
    os.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, os }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.cargo
            pkgs.rustc
            pkgs.rust-analyzer
          ];
        };

        packages = {
          launcher = pkgs.callPackage ./launcher { };
          platform = pkgs.callPackage ./platform { };
          yogaflow = pkgs.callPackage ./games/yogaflow { };
        };
      }
    ) // {
      nixosConfigurations = os.nixosConfigurations;
    };
}
