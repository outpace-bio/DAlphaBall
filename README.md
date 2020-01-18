# Conda Build Recipes

A  build recipe and associated scripting components for building conda
packages for Rosetta components. These recipes can be used to generate
the DAlphaBall executable.

## TLDR

1. Install `docker`.
2. Use `dalphaball_docker_build.sh <output dir>` to build the `dalphaball` 
   conda package.

## Build Layout

These components are roughly organized into layers:

- `recipes`: Conda recipe definitions with (a) dependency information and
    (b) basic build scripts.

- `build`: A wrapper around conda-build rendering version information for
  a given recipe with the current tree's version information.

- `dalphaball_docker_build.sh`: Script using minimal build
  environment defined in linux-anvil to build broadly compatible linux
  conda packages. This should be considered the primary entrypoint to
  generate conda packages.

## Build Debugging

The `dalphaball_docker_build.sh` build scripts can be used to
diagnose failed builds within the anvil environment. To debug a failed
build:

  * Note the build prefix in the container.
    Eg.

    `/home/conda/build/dalphaball_12345`

  * Re-invoke the `docker run` config used to execute the build, replacing
    the conda build call with a direct invocation of the workspace build
    script.

    Eg.
    `/home/conda/root/dalphaball/build dalphaball --croot /home/conda/build` 
    ->
    `bash -c 'cd /home/conda/build/dalphaball_12345 && ./conda_build.sh'`
