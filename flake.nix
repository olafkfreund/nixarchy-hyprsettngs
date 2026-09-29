{
  description = "nixarchy-hyprsetting: Hyprforge, the Hyprland studio for Omarchy, packaged for NixOS / Home Manager";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          pname = "nixarchy-hyprsetting";
          version = (builtins.fromJSON (builtins.readFile ./manifest.json)).version;
          # Only the plugin itself: no tests, docs or Nix files.
          src = pkgs.lib.fileset.toSource {
            root = ./.;
            fileset = pkgs.lib.fileset.unions [
              ./manifest.json ./Panel.qml ./Service.qml ./SafeWriter.qml ./BoundedRead.qml
              ./Engine.js ./Schema.js ./baseline.lua ./icon.svg ./preview.png ./LICENSE
              ./components
            ];
          };
          dontBuild = true;
          installPhase = "cp -r . $out";
          meta = {
            description = "Hyprland studio for Omarchy (Hyprforge by AbdulazizAlwabel)";
            homepage = "https://github.com/AbdulazizAlwabel/omarchy-hyprforge";
            license = pkgs.lib.licenses.mit;
            platforms = pkgs.lib.platforms.linux;
          };
        };
      });

      homeManagerModules.default = { config, lib, pkgs, ... }:
        let cfg = config.programs.nixarchy-hyprsetting; in
        {
          options.programs.nixarchy-hyprsetting = {
            enable = lib.mkEnableOption "the Hyprforge Omarchy plugin";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              description = "The plugin package linked into ~/.config/omarchy/plugins.";
            };
          };
          # One directory symlink; the id must stay aziz.hyprforge (state paths, IPC).
          # Enabling it in shell.json stays Omarchy's job: `omarchy plugin enable aziz.hyprforge`.
          config = lib.mkIf cfg.enable {
            xdg.configFile."omarchy/plugins/aziz.hyprforge".source = cfg.package;
          };
        };

      checks = forAll (pkgs: {
        default = pkgs.runCommand "nixarchy-hyprsetting-tests" {
          nativeBuildInputs = [ pkgs.nodejs pkgs.lua ];
        } ''
          cp -r ${./.} src && chmod -R u+w src && cd src
          node test/run.js
          touch $out
        '';
      });
    };
}
