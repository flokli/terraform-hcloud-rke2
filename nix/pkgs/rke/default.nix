{ stdenv
, fetchurl
}:
let
  version = "1.2.3";
in
stdenv.mkDerivation {
  inherit version;
  pname = "rke";

  src = fetchurl {
    url = "https://github.com/rancher/rke/releases/download/v${version}/rke_linux-amd64";
    sha256 = "0rlw7s80lmi0nvdxcb59vwmjd148680a1bcgwnzvs49i9n5l5fv1";
  };

  dontUnpack = true;
  doBuild = false;

  installPhase = ''
    install -Dm775 $src $out/bin/rke
  '';

  meta.platforms = [ "x86_64-linux" ];
}
