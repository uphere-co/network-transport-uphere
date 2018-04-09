{ mkDerivation, base, binary, bytestring, containers, data-accessor
, distributed-process, either, network, network-simple
, network-transport, stdenv, stm
}:
mkDerivation {
  pname = "network-transport-uphere";
  version = "0.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    base bytestring containers data-accessor network network-transport
  ];
  executableHaskellDepends = [
    base binary bytestring containers distributed-process either
    network-simple network-transport stm
  ];
  homepage = "http://haskell-distributed.github.com";
  description = "UpHere specific network transport";
  license = stdenv.lib.licenses.bsd3;
}
