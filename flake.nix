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
      in
      rec {
        devShell = import ./shell.nix { inherit pkgs; };
      }
    );
}
