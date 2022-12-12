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
    easel
    gnused
    jdk
    just
    infernal
    miller
    rEnv
    wget
  ];
}
