{
  description = "Framework 13 7640U ZFS Niri";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    
    niri.url = "github:sodiboo/niri-flake";
    
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs,... }@inputs: {
    nixosConfigurations.framework = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        inputs.disko.nixosModules.disko
        inputs.impermanence.nixosModules.impermanence
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
      ./disk-config.nix
      ./configuration.nix
      ];
    };
  };
}
