{
  description = "TOMORO OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko }:
    let
      system = "x86_64-linux";

      # A/B: same appliance config built twice, differing only in which
      # system partition it mounts as /.
      mkAppliance = slot: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit slot; };
        modules = [
          disko.nixosModules.disko
          ./hosts/appliance
        ];
      };
    in
    {
      nixosConfigurations = {
        # `appliance` = slot A; the installer ships this one.
        appliance = mkAppliance "a";
        appliance-a = mkAppliance "a";
        appliance-b = mkAppliance "b";

        iso = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit self; };
          modules = [ ./hosts/iso ];
        };


      };
    };
}
