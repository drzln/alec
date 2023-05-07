###############################################################################
# alec: a beautiful cli for ops awesomeness
###############################################################################

{
  #############################################################################
  # inputs
  #############################################################################

  inputs = {
    dream2nix.url = github:nix-community/dream2nix;
    flake-utils.url = github:numtide/flake-utils;
  };

  # end inputs

  #############################################################################
  # outputs
  #############################################################################
  outputs = { self, dream2nix, flake-utils }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        nixpkgs = dream2nix.inputs.nixpkgs;
        pkgs = nixpkgs.legacyPackages.${system};
        libs = nixpkgs.lib // builtins;

        d2n-flake = dream2nix.lib.makeFlakeOutputs {
          systemsFromFile = ./nix_systems;
          config.projectRoot = ./.;
          source = ./.;
          projects = ./projects.toml;
        };

        pkg = d2n-flake.packages.${system}.default;

        docker-flake = {
          pakcages = {
            "${system}" = {
              image = pkgs.dockerTools.buildImage {
                name = "alec";
                diskSize = 512;
                buildVMMemorySize = 512;
                copyToRoot = [ pkg ];
                config.Cmd = [ "${pkg}/bin/alec" ];
              };
            };
          };
        };
        flakes = dream2nix.lib.dlib.mergeFlakes [ d2n-flake docker-flake shell-flake ];

      in
      flakes
    );
}

# end alec #
