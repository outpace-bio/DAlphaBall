# Conda Build Recipes

A  build recipe and associated scripting components for building conda
packages for Rosetta components. These recipes can be used to generate
the DAlphaBall executable.

## TLDR

1. Install `docker`.
2. Use `dalphaball_docker_build.sh <output dir>` to build the `dalphaball`
   conda package.

## Building on/for macOS
The c std lib that can be used with conda build is a little older, so you'll
need to set up an appropriate build environment. The Mac OS X 10.10 SDK is
compatible and can be configured to work with conda build with the following
steps:

1. Get [MacOSX10.10.sdk](https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.10.sdk.tar.xz)
2. Move the SDK to `/opt` with `tar xf ~/Downloads/MacOSX10.10.sdk.tar.xz -C /opt`
3. Add the following to `~/.condarc`:
```
conda_build:
  config_file: ~/.conda/conda_build_config.yaml
```
4. Create `~/.conda/conda_build_config.yaml` if it doesn't exist and add:
```
CONDA_BUILD_SYSROOT:
  - /opt/MacOSX10.10.sdk # [osx]
```
5. Use `conda build recipes --croot=<output dir>` to build the `dalphaball`
   conda package.

## Build Layout

These components are roughly organized into layers:

- `recipes`: Conda recipe definitions with dependency information and build steps.

- `dalphaball_docker_build.sh`: Script using minimal build
  environment defined in linux-anvil to build broadly compatible linux
  conda packages. This should be considered the primary entrypoint to
  generate conda packages.

- Use `conda build recipes --croot=<output dir>` to build the `dalphaball`
  conda package in your current environment.

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
    `bash -c 'cd /home/conda/root/dalphaball && conda build recipes --croot /home/conda/build'`
    ->
    `bash -c 'cd /home/conda/build/dalphaball_12345 && ./conda_build.sh'`
