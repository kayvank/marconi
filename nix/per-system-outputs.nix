# This file is part of the IOGX template and is documented at the link below:
# https://www.github.com/input-output-hk/iogx#35-nixper-system-outputsnix

{ inputs, inputs', pkgs, projects }:

{

  packages.marconi-sidechain = inputs.self.packages.marconi-sidechain-exe-marconi-sidechain-ghc927;

}
