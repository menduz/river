# Builds river from this fork: the main branch of
# https://codeberg.org/river/river (the development version of river 0.6, after
# the release of 0.5.0) with patches. The recipe of nixpkgs for river builds
# it. This file changes only the source, the version and the Zig
# dependencies.
#
# `riverSource` and `version` are for a flake that has this fork as an input,
# for example:
#
#   pkgs.callPackage "${inputs.river}/nix" {
#     riverSource = inputs.river;
#     version = "0.6.0-dev-${inputs.river.shortRev or "dirty"}";
#   }
#
# Without them, the recipe builds the files of this repository. (callPackage
# gives the river of nixpkgs in the argument `river`.)
#
# After a change of the Zig dependencies in build.zig.zon, the hash below
# changes. Then the build fails and shows the new hash. Put that hash below.
{
  river,
  callPackage,
  riverSource ? ../.,
  version ? "0.6.0-dev",
}:
let
  zigSystemDeps = callPackage ./zig-system-deps.nix { };

  # The files of the build. A change of the Nix files does not build river
  # again.
  source = builtins.path {
    name = "river-source";
    path = riverSource;
    filter =
      path: type:
      !(builtins.elem (baseNameOf path) [
        ".git"
        ".zig-cache"
        "zig-out"
        "zig-pkg"
        "result"
        "nix"
      ]);
  };
in
river.overrideAttrs (
  finalAttrs: previousAttrs: {
    inherit version;
    src = source;

    deps = zigSystemDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-1TW4SRIcrBvJSU9m+tCa9mwQK3PRzrNxGOlRwoiVrp4=";
    };

    # The source has no .git directory. Without this flag, build.zig runs git
    # to find the version.
    zigBuildFlags = previousAttrs.zigBuildFlags ++ [ "-Dversion-string=${finalAttrs.version}" ];

    passthru = previousAttrs.passthru // {
      updateScript = null;
    };
  }
)
