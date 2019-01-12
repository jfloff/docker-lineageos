# docker-lineageos

[![Docker Stars](https://img.shields.io/docker/stars/jfloff/lineageos.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/jfloff/lineageos.svg)][hub]

[hub]: https://hub.docker.com/r/jfloff/lineageos/

Docker container for building [LineageOS](https://lineageos.org/) (formerly known as CyanogenMod).

<!-- MDTOC maxdepth:6 firsth1:0 numbering:0 flatten:0 bullets:1 updateOnSave:1 -->

- [Why?](#why)
- [Usage](#usage)
- [Building a custom device configuration](#building-a-custom-device-configuration)
- [`lineageos` script](#lineageos-script)
- [License](#license)

<!-- /MDTOC -->

### TLDR

**Note**: Remember that LineageOS is a huge project. It will consume a large amount of disk space (~80 GB).

```shell
# pass required env variables
$ docker run --rm --privileged \
  -v "$(pwd)/android":/home/lineageos \
  -e GIT_USER_NAME=jfloff \
  -e GIT_USER_EMAIL=jfloff@inesc-id.pt \
  -e DEVICE_CODENAME=klte \
  -ti jfloff/lineageos lineageos init build

# or pass a custom .env file
$ docker run --rm --privileged \
  -v "$(pwd)/android":/home/lineageos \
  --env-file custom.env
  -ti jfloff/lineageos lineageos init build
```


<!-- MDTOC maxdepth:6 firsth1:0 numbering:0 flatten:0 bullets:1 updateOnSave:1 -->
- [Why?](#why)
- [Usage](#usage)
- [Building a custom device configuration](#building-a-custom-device-configuration)
- [`lineageos` script](#lineageos-script)
- [License](#license)
<!-- /MDTOC -->


## Why?

Existing Docker images only provide a container with all the [dependencies installed](https://github.com/LineageOS/docker_build), and still require the user the [manually input most build commands](https://github.com/stucki/docker-lineageos#how-to-build-lineageos-for-your-device). There have been some attempts to have a more [automated](https://github.com/AnthoDingo/docker-lineageos) based on scripts, but they lack flexibility when building the repository (for example, they expect you to input the devices' proprietary blobs in between steps). On top of these issues, most of the repos use Ubuntu as their base image (which is known for being a large base image) and do not follow the Dockerfile recommendations (unoptimized layer caching).

We strive for more _automation_. Our goal is for users to be able to compile LineageOS for a specific device with _**single**_ `docker run` command. Let's go over what was done in this image.

## Usage

The main working directory is a shared folder on the host system, so the Docker container can be removed at any time and used just to build. For example, `-v "$(pwd)/android":/home/lineageos`: here we are mounting the `android` directory into the `$BASE_DIR` directory which by default is `/home/lineageos`.

Next, we have to set the device we want to build through an env variable, for example `-e DEVICE_CODENAME=klte`. This will also trigger the default configuration for that device (if a configuration available in the [`device-config` folder](device-config/)).

Finally we also have to set our git user information,  for example `-e GIT_USER_NAME=jfloff -e GIT_USER_EMAIL=jfloff@inesc-id.pt`.

This should be the minimium working example for this image. Note however that `klte` device has a configuration available in the [`device-config`](device-config/).
```shell
$ docker run --rm --privileged \
  -v "$(pwd)/android":/home/lineageos \
  -e GIT_USER_NAME=jfloff \
  -e GIT_USER_EMAIL=jfloff@inesc-id.pt \
  -e DEVICE_CODENAME=klte \
  -ti jfloff/lineageos lineageos init build
```

Instead of settings multiple env variables, you can also pass an env-file (as per [docker run reference](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e-env-env-file)).
```shell
$ docker run --rm --privileged \
  -v "$(pwd)/android":/home/lineageos \
  --env-file custom.env
  -ti jfloff/lineageos lineageos init build
```

Note that we ran `lineageos init build` which is our custom script that is used to help init, sync and build LineageOS form within the container. Check `lineageos` script details below.

**If your device doesn't have an env configuration available in the [`device-config`](device-config/) folder, you have to build a custom device configuration. We show how you [build your own configuration below](#building-a-custom-device-configuration)**.

Here is a list of devices that have configuration files available (check [`device-config`](device-config/) folder):
- `klte`
- `kltevzw`
- `bacon` (thanks @GRBurst)
- `mako` (thanks @brainstorm)
- `jfltexx` (thanks  @BenJule)

_**Feel free to open a PR to submit another device configuration.**_

## `lineageos` script
Inside the container there is script, called [`lineageos`](lineageos), that's used to automate most of the commands needed to init, sync and build LineageOS.  Let's go go over each option:
- `-c|--clean`: Removes all the repo files (cache included)
- `i|init`: Initializes the repository making it ready to build LineageOS. In this step we init the repo and sync it. We also download the device's proprietary blobs, the user's extra files, and enable caching.
- `b|build`: Builds LineageOS!
- `s|sync`: Forces sync of the LineageOS repo sync and (if set) of the device's proprietary blobs repo
- `all`: Shortcut for performing `lineageos init build`

Remember you can compose multiple instructions, for example, for a completly clean build you can run `lineageos all --clean` (or `lineageos -c init build`).

## Building a custom device configuration

A device configuration is a simple file with several env variables set (you can also pass these variables directly to `docker run`). All the magic happens underneath.

**NOTE**: Any env variables you pass as will overwrite the default configurations (from the [`default.env` file](default.env)), and the pre-existing device-specific configuration files from the [`device-config`](device-config/) folder. I.e., the precedence order looks something like this: _custom env_ > _device-config-file.env_ > _default.env_

Here is a rundown of all the variables that you can set.

| Variable | Description | Type | Default |
| -------- | ----------- | ---- | ------- |
| **`GIT_USER_NAME`** | Username for git. <br>*Example*: João Loff | _**Required**_ | |
| **`GIT_USER_EMAIL`** | User email for git. <br>*Example*: jfloff@inesc-id.pt | _**Required**_ | |
| **`DEVICE_CODENAME`** | Device's codename (see [more](https://wiki.lineageos.org/devices/)). <br>*Example*: `klte` | _**Required**_ | |
| **`BASE_DIR`** | Directory where host volume with LineageOS was mounted | *optional* | `/home/$USER` |
| **`LINEAGEOS_REPO`** | LineageOS repository | *optional* | `https://github.com/LineageOS/android.git` |
| **`LINEAGEOS_BRANCH`** | LineageOS Branch. | *optional* | `cm-14.1` |
| **`PROPRIETARY_BLOBS_REPO`** | Repo with the [device's proprietary blobs](https://wiki.lineageos.org/devices/klte/build#extract-proprietary-blobs). <br>*Example*: `https://github.com/TheMuppets/proprietary_vendor_samsung` |  *optional* | |
| **`PROPRIETARY_BLOBS_DIR`** | Directory to where the repo with the device's blobs will be cloned to. <br>*Example*: `$BASE_DIR/vendor/samsung` | *optional* | |
| **`USE_CCACHE`** | Turn on caching to speed up build (see [more](https://wiki.lineageos.org/devices/klte/build#turn-on-caching-to-speed-up-build)) | *optional* | `1` |
| **`CCACHE_SIZE`** | Maximum amount of cache disk space allowed | *optional* | `50G` |
| **`CCACHE_COMPRESS`** | Enable the `ccache` compression | *optional* | `1` |
| **`CCACHE_DIR`** | Directory used for caching | *optional* | `$BASE_DIR/cache` |
| **`ANDROID_JACK_VM_ARGS`** | Fixes [out-of-memory error for Jack compiler](https://wiki.lineageos.org/devices/klte/build#configure-jack). Increase the assigned memory if necessary | *optional* | `"-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"` |
| **`WITH_SU`** | Builds rom with root access | *optional* | `false` |
| **`PRE_SYNC_SCRIPT`** | Path to script to run before `sync`. <br>*Example*: `/home/scripts/pre_sync.sh` | *optional* |  |
| **`PRE_BUILD_SCRIPT`** | Path to script to run before `build`. <br>*Example*: `/home/scripts/pre_build.sh` | *optional* |  |
| **`POST_BUILD_SCRIPT`** | Path to script to run after `build`. <br>*Example*: `/home/scripts/post_build.sh` | *optional* |  |

You can pass any other env variable that you need, or just do some scripting. It's that flexible!

You also have a _template_-like env variable with the following format `EXTRA_DOWNLOAD_<ID>` that you can use to download extra files before you build. This template can be useful to download some files like the device's proprietary blobs that were obtain from the device itself (you can place those files in a link somewhere, and the script will download them), or just overall missing files while building.

These variables have to use the following template `EXTRA_DOWNLOAD_<ID>=("<URL>" "<TARGET_PATH>")`, where `URL` is the url where the file is located and will be downloaded from (using curl), and `<TARGET_PATH>` is the folder (inside the container) to which the file will be downloaded to.

For example, the following env will download the file `msm8974pro_sec_klte_vzw_defconfig` to `kernel/samsung/klte/arch/arm/configs/`:
```shell
EXTRA_DOWNLOAD_1=(
    'https://raw.githubusercontent.com/badowl/android_kernel_samsung_klte/cm-14.1/arch/arm/configs/msm8974pro_sec_klte_vzw_defconfig'
    'kernel/samsung/klte/arch/arm/configs/msm8974pro_sec_klte_vzw_defconfig'
)
```




## License
MIT (see [LICENSE](LICENSE))
