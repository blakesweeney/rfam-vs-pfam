{ pkgs ? import <nixpkgs> {} }:
let 
  rEnv = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      tidyverse
    ];
  };
in
pkgs.devshell.mkShell {
  name = "family-stats-shell";
  motd = "";

  packages = with pkgs; [
    coreutils
    easel
    gnused
    infernal
    jdk
    just
    miller
    rEnv
    seqkit
    wget
  ];
}
