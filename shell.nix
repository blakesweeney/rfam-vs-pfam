{ pkgs ? import <nixpkgs> {} }:
pkgs.devshell.mkShell {
  name = "family-stats-shell";
  motd = "";

  packages = with pkgs; [
    easel
    infernal
    jdk
    wget
    xsv
  ];
}
