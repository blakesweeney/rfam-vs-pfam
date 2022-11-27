{ pkgs ? import <nixpkgs> {} }:
pkgs.devshell.mkShell {
  name = "family-stats-shell";
  motd = "";

  packages = with pkgs; [
    easel
    gnused
    infernal
    jdk
    miller
    wget
    xsv
  ];
}
