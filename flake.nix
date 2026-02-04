{
  description = "Polished screenshot utility for Hyprland built with Quickshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      runtimeDeps = with pkgs; [
        quickshell
        grim
        imagemagick
        wl-clipboard
        satty
      ];
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "hyprquickframe";
        version = "0.1.0";
        src = ./.;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        installPhase = ''
          mkdir -p $out/share/hyprquickframe
          cp -r * $out/share/hyprquickframe/

          makeWrapper ${pkgs.quickshell}/bin/quickshell $out/bin/hyprquickframe \
            --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
            --add-flags "-c $out/share/hyprquickframe -n"
        '';

        meta = with pkgs.lib; {
          description = "Quickshell-based screenshot utility for Hyprland";
          homepage = "https://github.com/Ronin-CK/HyprQuickFrame";
          license = licenses.mit;
          platforms = platforms.linux;
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = runtimeDeps;
      };
    };
}
