{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixant.url = "github:jasalt/nixant-py";
    nixant.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, nixant, ... }: {
    nixosConfigurations.dev = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixant.nixosModules.container
        nixant.nixosModules.wordpress
        ./nix/site.nix
      ];
    };
  };
}
