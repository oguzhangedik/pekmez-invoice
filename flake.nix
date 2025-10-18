{
  description = "Pekmez invoice maker";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      nixpkgs,
      systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      pkgsFor = lib.genAttrs (import systems) (system: import nixpkgs { inherit system; });
      forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
    in
    {
      packages = forEachSystem (pkgs: {
        default = pkgs.callPackage ./invoice.nix { };
      });

      defaultPackage = {
        x86_64-linux = pkgsFor.x86_64-linux.callPackage ./invoice.nix { };
        x86_64-darwin = pkgsFor.x86_64-darwin.callPackage ./invoice.nix { };
      };

      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            typst
          ];
        };
      });
    };
}
