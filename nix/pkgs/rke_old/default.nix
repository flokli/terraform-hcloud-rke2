{ stdenv
, fetchurl
}:
let
  version = "1.0.14";
in
stdenv.mkDerivation {
  inherit version;
  pname = "rke";

  src = fetchurl {
    url = "https://github.com/rancher/rke/releases/download/v${version}/rke_linux-amd64";
    sha256 = "1yc9gkifxqf0hyrf2d9n8w9mh5wf3rlxr4v5x801lflsxpsjhdn7";
  };

  dontUnpack = true;
  doBuild = false;

  installPhase = ''
    install -Dm775 $src $out/bin/rke
  '';

  meta.platforms = [ "x86_64-linux" ];
}
