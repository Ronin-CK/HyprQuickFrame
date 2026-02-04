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
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = "hyprquickframe";
          version = "0.1.0";
          src = ./.;

          inherit (pkgs.stdenv.hostPlatform) system;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          buildInputs = with pkgs; [
            quickshell
            grim
            imagemagick
            wl-clipboard
            satty
          ];

          installPhase = ''
            mkdir -p $out/share/hyprquickframe
            cp -r * $out/share/hyprquickframe/

            makeWrapper ${pkgs.quickshell}/bin/quickshell $out/bin/hyprquickframe \
              --prefix PATH : ${
                pkgs.lib.makeBinPath (
                  with pkgs;
                  [
                    quickshell
                    grim
                    imagemagick
                    wl-clipboard
                    satty
                  ]
                )
              } \
              --add-flags "-c $out/share/hyprquickframe -n"
          '';

          meta = with pkgs.lib; {
            description = "Quickshell-based screenshot utility for Hyprland";
            homepage = "https://github.com/Ronin-CK/HyprQuickFrame";
            license = licenses.mit;
            platforms = platforms.linux;
          };
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            quickshell
            grim
            imagemagick
            wl-clipboard
            satty
          ];
        };
      });
    };
}
