{
  description = "Python Jupyter environment for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        buildLibs = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          glib
          libGL
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python312
            python312Packages.pip
            python312Packages.virtualenv
            gcc
            pkg-config
          ];

          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath buildLibs}:$LD_LIBRARY_PATH"

            # Автоматически создаем и активируем .venv на Python 3.12, если его нет
            if [ ! -d ".venv" ]; then
              echo "Creating virtual environment..."
              python -m venv .venv
              source .venv/bin/activate
              pip install --upgrade pip
              pip install ipykernel jupyter pyzmq
            else
              source .venv/bin/activate
            fi
          '';
        };
      });
}
