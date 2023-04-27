{
  description = "My config for (neo)vim";

  inputs = {
    dev-shell = { url = "github:numtide/devshell"; inputs.nixpkgs.follows = "nixpkgs"; };
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    personal = {
      url = "git+ssh://git@git.sr.ht/~showyourcode/flakes?ref=main";
      inputs = {
        dev-shell.follows = "dev-shell";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    inputs.utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            inputs.dev-shell.overlay
            inputs.personal.overlay
          ];
        };
        rEnv = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            tidyverse
            languageserver
            viridis
            ggbeeswarm
            ggridges
            ggpubr
            ggh4x
          ];
        };
      in
      rec {
        devShell = pkgs.devshell.mkShell {
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
            nextflow
            nodePackages.pyright
            python39
            rEnv
            seqkit
            wget
          ];
        };
      }
    );
}
