{
  description = "Polished screenshot utility for Hyprland built with Quickshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f (import nixpkgs { inherit system; }));
      
      # Define runtime dependencies once
      runtimeDeps = pkgs: with pkgs; [
        quickshell
        grim
        imagemagick
        wl-clipboard
        satty
      ];
    in
    {
      overlays.default = final: prev: {
        hyprquickframe = self.packages.${final.system}.default;
      };

      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = "hyprquickframe";
          version = "0.1.0";
          
          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter = path: type:
              let
                baseName = baseNameOf path;
              in
              ! (builtins.elem baseName [
                "flake.nix"
                "flake.lock"
                ".git"
                ".gitignore"
                "README.md"
                "LICENSE"
              ]);
          };

          nativeBuildInputs = [ pkgs.makeWrapper ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/hyprquickframe
            cp -r . $out/share/hyprquickframe/

            mkdir -p $out/bin
            makeWrapper ${pkgs.quickshell}/bin/quickshell $out/bin/hyprquickframe \
              --prefix PATH : ${pkgs.lib.makeBinPath (runtimeDeps pkgs)} \
              --add-flags "-c $out/share/hyprquickframe/shell.qml"

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Quickshell-based screenshot utility for Hyprland";
            homepage = "https://github.com/Ronin-CK/HyprQuickFrame";
            license = licenses.mit;
            platforms = platforms.linux;
            mainProgram = "hyprquickframe";
          };
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          buildInputs = runtimeDeps pkgs;
        };
      });
    };
}
