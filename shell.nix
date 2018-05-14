{ revision }:

with revision;

let pkgs0 = import nixpkgs { config.allowUnfree = true; };

    pkgs = import pkgs0.path {
                overlays = [ (self: super: {
                               libsvm = import (uphere-nix-overlay + "/nix/cpp-modules/libsvm/default.nix") { inherit (self) stdenv fetchurl; };
                             })
                           ];
              };
in

with pkgs;

let

  fasttext = import (uphere-nix-overlay + "/nix/cpp-modules/fasttext.nix") { inherit stdenv fetchgit; };
  res_corenlp = import (uphere-nix-overlay + "/nix/linguistic-resources/corenlp.nix") {
    inherit fetchurl fetchzip srcOnly;
  };
  corenlp = res_corenlp.corenlp;
  corenlp_models = res_corenlp.corenlp_models;

  hsconfig = lib.callPackageWith (pkgs//revision)
               (uphere-nix-overlay + "/nix/haskell-modules/configuration-semantic-parser-api.nix") {
                 inherit corenlp corenlp_models fasttext;
               };


  newHaskellpkgs = haskellPackages.override { overrides = hsconfig; };

  hsenv = newHaskellpkgs.ghcWithPackages (p: with p; [
            network-transport
            distributed-process
            lens
            either
            network
            network-simple
          ]);

in

stdenv.mkDerivation {
  name = "network-transport-uphere-dev";
  buildInputs = [ hsenv ];
  shellHook = ''
  '';
}
