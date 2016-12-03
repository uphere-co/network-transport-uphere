{ nixpkgs ? import <nixpkgs> {}, compiler ? "default" }:

let

  inherit (nixpkgs) pkgs;

  f = { mkDerivation, base, bytestring, containers, data-accessor
      , network, network-transport, network-transport-tests, stdenv
      , cabal-install
      }:
      mkDerivation {
        pname = "network-transport-uphere";
        version = "0.0";
        src = ./.;
        libraryHaskellDepends = [
          base bytestring containers data-accessor network network-transport
        ];
        testHaskellDepends = [
          base network network-transport network-transport-tests
        ];
	buildDepends = [ cabal-install ];
        homepage = "http://haskell-distributed.github.com";
        description = "UpHere specific network transport";
        license = stdenv.lib.licenses.bsd3;
      };

  haskellPackages = if compiler == "default"
                       then pkgs.haskellPackages
                       else pkgs.haskell.packages.${compiler};

  drv = haskellPackages.callPackage f {};

in

  if pkgs.lib.inNixShell then drv.env else drv
