{
  description = "Dev environment for Kubernetes-and-DevOps (From Code to Cluster)";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        # Course pins kind v0.33.0 (node kindest/node:v1.37.0); nixpkgs still ships 0.32.
        kind = pkgs.kind.overrideAttrs (old: rec {
          version = "0.33.0";
          src = pkgs.fetchFromGitHub {
            owner = "kubernetes-sigs";
            repo = "kind";
            rev = "v${version}";
            hash = "sha256-exqO/KERw/SOv3dywcrm/DSHY37dfTOhQezg6Nroew0=";
          };
          # nixpkgs backports upstream commit 9a24e6c; v0.33.0 already contains it.
          patches = builtins.filter (p: !(pkgs.lib.hasInfix "9a24e6c1" (toString p))) (old.patches or [ ]);
          vendorHash = "sha256-tRpylYpEGF6XqtBl7ESYlXKEEAt+Jws4x4VlUVW8SNI=";
        });
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            kind
            kubectl
            go_1_27
            git
            gh
            docker-client
            curl
            jq
          ];
        };
      });
}
