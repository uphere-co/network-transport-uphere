{ nixpkgs ? import <nixpkgs> {}, compiler ? "default" }:

let

  inherit (nixpkgs) pkgs;

  f = { mkDerivation, base, bytestring, containers, data-accessor
      , network, network-simple, network-transport, network-transport-tests, either
      , stdenv
      , cabal-install
      , distributed-process
      }:
      mkDerivation {
        pname = "network-transport-uphere";
        version = "0.0";
        src = ./.;
        libraryHaskellDepends = [
          base bytestring containers data-accessor network network-simple network-transport
        ];
        executableHaskellDepends = [
          base network-transport either distributed-process
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
