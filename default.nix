{ mkDerivation, base, bytestring, containers, data-accessor
, network, network-transport, network-transport-tests, either
, stdenv
}:
mkDerivation {
  pname = "network-transport-uphere";
  version = "0.0";
  src = ./.;
  libraryHaskellDepends = [
    base bytestring containers data-accessor network network-transport
  ];
  executableHaskellDepends = [
    base network-transport either
  ];
  homepage = "http://haskell-distributed.github.com";
  description = "UpHere specific network transport";
  license = stdenv.lib.licenses.bsd3;
  doCheck = false;
}
