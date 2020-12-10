self: super: with super; {
  #rke = self.callPackage ./pkgs/rke { };
  rke = self.callPackage ./pkgs/rke_old { };
}
