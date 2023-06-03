
# Conda Build Recipes
DAlphaBall is distributed under the GNU LGPL. A  build recipe and associated scripting components for building conda
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
5. Create and activate a new conda environment (or activate an existing conda environment), 
installing `conda-build` and `pyrosetta` packages. For older versions of conda (<=4.6), one may need to install
`conda-build<=3.22.0` to avoid an `ImportError` at the next stage.
6. Navigate to this cloned repository directory, and use `conda build recipes -c conda-forge --croot=<output dir>`
to build the `dalphaball` conda package.
7. In order to use the `dalphaball` package with `pyrosetta`, then use `conda install dalphaball -c <output dir>`
to install `dalphaball` into the active conda environment. Optionally, it may be installed into any conda environment
at this stage. 
8. The `dalphaball` executable is then located in the conda environment `bin` directory, usually located here:
`~/opt/anaconda3/envs/MYENV/bin/dalphaball`
9. Initialize PyRosetta with the following flag: `-holes:dalphaball ~/opt/anaconda3/envs/MYENV/bin/dalphaball`
10. Enable usage of dalphaball in the `BuriedUnsatHbonds` filter with the `dalphaball_sasa="1"` option. The `Holes`
filter automatically uses it.

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
