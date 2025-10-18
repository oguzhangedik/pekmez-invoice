{
  description = "Pekmez invoice maker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { nixpkgs, systems, ... }:
    let
      inherit (nixpkgs) lib;
      supportedSystems = import systems;

      forAllSystems = f:
        lib.genAttrs supportedSystems (system:
          f {
            pkgs = import nixpkgs { inherit system; };
          });

      pkgsFor = lib.genAttrs supportedSystems (system:
        import nixpkgs { inherit system; });

      # Windows cross-compilation (from Linux)
      windowsCrossPkgs = import nixpkgs {
        system = "x86_64-linux";
        crossSystem = {
          config = "x86_64-w64-mingw32";
          system = "x86_64-windows";
        };
      };

    in
    {
      packages = forAllSystems ({ pkgs }: {
        default = pkgs.callPackage ./invoice.nix { };
      }) // {
        x86_64-windows = windowsCrossPkgs.callPackage ./invoice.nix { };
      };

      defaultPackage = {
        x86_64-linux = pkgsFor.x86_64-linux.callPackage ./invoice.nix { };
        x86_64-darwin = pkgsFor.x86_64-darwin.callPackage ./invoice.nix { };
        x86_64-windows = windowsCrossPkgs.callPackage ./invoice.nix { };
      };

      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ typst ];
        };
      });
    };
}
