#! /usr/bin/env bash
#
# Copyright 2019 by userdocs and contributors
#
# SPDX-License-Identifier: Apache-2.0
#
# @author - userdocs
#
# @contributors IceCodeNew
# 
# @credits - https://gist.github.com/notsure2
#
## https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#
set -e
#
## Do not edit these variables. They set the default values to some critical variables.
#
WORKING_DIR="$(printf "$(dirname "$0")" | pwd)" # used for the cd commands to cd back to the working directory the script was executed from.
PARAMS=""
BUILD_DIR=""
SKIP_DELETE='no'
SKIP_BISON='no'
SKIP_GAWK='no'
SKIP_GLIBC='no'
SKIP_ICU='yes'
GITHUB_TAG=''
GIT_PROXY=''
CURL_PROXY=''
STATIC='yes'
#
## This section controls our flags that we can pass to the script to modify some variables and behaviour.
#
while (( "$#" )); do
  case "$1" in
    -b|--build-directory)
      BUILD_DIR="$2"
      shift 2
      ;;
    -n|--no-delete)
      SKIP_DELETE='yes'
      shift
      ;;
    -i|--icu)
      SKIP_ICU='no'
      shift
      ;;
    -m|--master)
      GITHUB_TAG='master'
      shift
      ;;
    -p|--proxy)
      export GIT_PROXY="-c http.sslVerify=false -c http.https://github.com.proxy=$2"
      export CURL_PROXY="-x $2"
      shift
      ;;
    -h|--help)
      echo -e "\n\e[1mDefault build location:\e[0m \e[32m$HOME/qbittorrent-build\e[0m"
      echo -e "\n\e[32m-b\e[0m or \e[32m--build-directory\e[0m to set the location of the build directory. Paths are relative to the script location. Recommended that you use a full path."
      echo -e "\n\e[32mall\e[0m - install all modules to the default or specific build directory (when -b is used)"
      #
      echo -e "\n\e[1mExample:\e[0m \e[32m$(basename -- "$0") all\e[0m - Will install all modules and build qbittorrent to the default build location"
      echo -e "\n\e[1mExample:\e[0m \e[32m$(basename -- "$0") all -b \"\$HOME/build\"\e[0m - Will specify a build directory and install all modules to that custom location"
      echo -e "\n\e[1mExample:\e[0m \e[32m$(basename -- "$0") module\e[0m - Will install a single module to the default build location"
      echo -e "\n\e[1mExample:\e[0m \e[32m$(basename -- "$0") module -b \"\$HOME/build\"\e[0m - will specify a custom build directory and install a specific module use to that custom location"
      #
      echo -e "\n\e[32mmodule\e[0m - install a specific module to the default or defined build directory"
      echo -e "\n\e[1mSupported modules\e[0m"
      echo -e "\n\e[95mzlib\nicu\nopenssl\nboost_build\nboost\nqtbase\nqttools\nlibtorrent\nqbittorrent\e[0m"
      #
      echo -e "\n\e[1mPost build options\e[0m"
      echo -e "\nThe binary can be installed using the install argument."
      echo -e "\n\e[32m$(basename -- "$0") install\e[0m"
      echo -e "\nIf you installed to a specified build directory you need to specify that location using -b"
      echo -e "\n\e[32m$(basename -- "$0") install -b \"\$HOME/build\"\e[0m"
      #
      echo -e "\nThe installation directories depend on the user executing the script."
      echo -e "\nroot = \e[32m/usr/local\e[0m"
      echo -e "\nlocal = \e[32m\$HOME/bin\e[0m\n"
      exit 1
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo -e "\nError: Unsupported flag - \e[31m$1\e[0m - use \e[32m-h\e[0m or \e[32m--help\e[0m to see the valid options\n" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
#
## Set positional arguments in their proper place.
#
eval set -- "$PARAMS"
#
## The build and installation directory. If the argument -b is used to set a build dir that directory is set and used. If nothing is specified or the switch is not used it defaults to the hard-coded ~/qbittorrent-build
#
if [[ -n "$BUILD_DIR" ]]; then
    if [[ "$BUILD_DIR" =~ ^/ ]]; then
        export install_dir="$BUILD_DIR"
    else
        export install_dir="${HOME}/${BUILD_DIR}"
    fi
else
    export install_dir="$HOME/qbittorrent-build"
fi
#
## Echo the build directory.
#
echo -e "\n\e[1mInstall Prefix\e[0m : \e[32m$install_dir\e[0m"
#
## Some basic help
#
echo -e "\n\e[1mScript help\e[0m : \e[32m$(basename -- "$0") -h\e[0m"
#
## This is a list of all modules.
#
modules='^(all|bison|gawk|glibc|zlib|icu|openssl|boost_build|boost|qtbase|qttools|libtorrent|qbittorrent)$'
#
## The installation is modular. You can select the parts you want or need here or using ./scriptname module or install everything using ./scriptname all
#
[[ "$1" = 'all' ]] && skip_bison="$SKIP_BISON" || skip_bison='yes'
[[ "$1" = 'all' ]] && skip_gawk="$SKIP_GAWK" || skip_gawk='yes'
[[ "$1" = 'all' ]] && skip_glibc="$SKIP_GLIBC" || skip_glibc='yes'
[[ "$1" = 'all' ]] && skip_zlib='no' || skip_zlib='yes'
[[ "$1" = 'all' ]] && skip_icu="$SKIP_ICU" || skip_icu='yes'
[[ "$1" = 'all' ]] && skip_openssl='no' || skip_openssl='yes'
[[ "$1" = 'all' ]] && skip_boost_build='no' || skip_boost_build='yes'
[[ "$1" = 'all' ]] && skip_boost='no' || skip_boost='yes'
[[ "$1" = 'all' ]] && skip_qtbase='no' || skip_qtbase='yes'
[[ "$1" = 'all' ]] && skip_qttools='no' || skip_qttools='yes'
[[ "$1" = 'all' ]] && skip_libtorrent='no' || skip_libtorrent='yes'
[[ "$1" = 'all' ]] && skip_qbittorrent='no' || skip_qbittorrent='yes'
#
## Set this to assume yes unless set to no by a dependency check.
#
deps_installed='yes'
#
## Check for required and optional dependencies
#
echo -e "\n\e[1mChecking if required core dependencies are installed\e[0m\n"
#
[[ "$(dpkg -s build-essential 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - build-essential" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - build-essential"; }
[[ "$(dpkg -s pkg-config 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - pkg-config" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - pkg-config"; }
[[ "$(dpkg -s automake 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - automake" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - automake"; }
[[ "$(dpkg -s libtool 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - libtool" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - libtool"; }
[[ "$(dpkg -s git 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - git" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - git"; }
[[ "$(dpkg -s perl 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - perl" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - perl"; }
[[ "$(dpkg -s python3 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - python3" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - python3"; }
[[ "$(dpkg -s python3-dev 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - python3-dev" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - python3-dev"; }
#
## Check if user is able to install the depedencies, if yes then do so, if no then exit.
#
if [[ "$deps_installed" = 'no' ]]; then
    if [[ "$(id -un)" = 'root' ]]; then
        #
        echo -e "\n\e[32mUpdating\e[0m\n"
        #
        set +e
        #
        apt-get update -y
        apt-get upgrade -y
        apt-get autoremove -y
        #
        set -e
        #
        [[ -f /var/run/reboot-required ]] && { echo -e "\n\e[31mThis machine requires a reboot to continue installation. Please reboot now.\e[0m\n"; exit; } || :
        #
        echo -e "\n\e[32mInstalling required dependencies\e[0m\n"
        #
        apt-get install -y build-essential pkg-config automake libtool git perl python3 python3-dev
        #
        echo -e "\n\e[32mDependencies installed!\e[0m"
        #
        deps_installed='yes'
        #
    else
        echo -e "\n\e[1mPlease request or install the missing core dependencies before using this script\e[0m"
        #
        echo -e '\napt-get install -y build-essential pkg-config automake libtool git perl python3 python3-dev\n'
        #
        exit
    fi
fi
#
## All checks passed echo
#
if [[ "$deps_installed" = 'yes' ]]; then
    echo -e "\n\e[1mGood, we have all the core dependencies installed, continuing to build\e[0m"
fi
#
## Set some python variables we need.
#
export python_version="$(python3 -V | awk '{ print $2 }')"
export python_short_version="$(echo "$python_version" | sed 's/\.[^.]*$//')"
export python_link_version="$(echo "$python_version" | cut -f1 -d'.')$(echo "$python_version" | cut -f2 -d'.')"
#
## post build install command via positional parameter.
#
if [[ "$1" = 'install' ]];then
    if [[ -f "$install_dir/bin/qbittorrent-nox" ]]; then
        #
        if [[ "$(id -un)" = 'root' ]]; then
            mkdir -p "/usr/local/bin"
            cp -rf "$install_dir/bin/qbittorrent-nox" "/usr/local/bin"
        else
            mkdir -p "$HOME/bin"
            cp -rf "$install_dir/bin/qbittorrent-nox" "$HOME/bin"
        fi
        #
        echo -e '\nqbittorrent-nox has been installed!\n'
        echo -e 'Run it using this command:\n'
        #
        [[ "$(id -un)" = 'root' ]] && echo -e '\e[32mqbittorrent-nox\e[0m\n' || echo -e '\e[32m~/bin/qbittorrent-nox\e[0m\n'
        #
        exit
    else
        echo -e "\nqbittorrent-nox has not been built to the defined install directory:\n"
        echo -e "\e[32m$install_dir\e[0m\n"
        echo -e "Please build it using the script first then install\n"
        #
        exit
    fi
fi
#
## Create the configured install directory.
#
[[ "$1" =~ $modules ]] && { mkdir -p "$install_dir/logs"; mkdir -p "$install_dir/completed"; echo 'using python : '"$python_short_version"' : /usr/bin/python'"$python_short_version"' : /usr/include/python'"$python_short_version"' : /usr/lib/python'"$python_short_version"' ;' > "$HOME/user-config.jam"; }
#
## Set lib and include directory paths based on install path.
#
export include_dir="$install_dir/include"
export lib_dir="$install_dir/lib"
#
## Set some build settings we need applied
#
custom_flags_set () {
    export CXXFLAGS="-std=c++14"
    export CPPFLAGS="--static -static -I$include_dir"
    export LDFLAGS="--static -static -Wl,--no-as-needed -L$lib_dir -lpthread -pthread"
}
#
custom_flags_reset () {
    export CXXFLAGS="-std=c++14"
    export CPPFLAGS=""
    export LDFLAGS=""
}
#
## Define some build specific variables
#
export PATH="$install_dir/bin:$HOME/bin${PATH:+:${PATH}}"
export LD_LIBRARY_PATH="-L$lib_dir"
export PKG_CONFIG_PATH="-L$lib_dir/pkgconfig"
export local_boost="--with-boost=$install_dir"
export local_openssl="--with-openssl=$install_dir"
#
## Functions
#
curl () {
    if [[ -z "$CURL_PROXY" ]]; then
        "$(type -P curl)" -sSLN4q --connect-timeout 5 --retry 5 --retry-delay 10 --retry-max-time 60 "$@"
    else
        "$(type -P curl)" -sSLN4q --connect-timeout 5 --retry 5 --retry-delay 10 --retry-max-time 60 --proxy-insecure ${CURL_PROXY} "$@" 
    fi
}
#
download_file () {
    url_filename="${2}"
    [[ -n "$3" ]] && subdir="/$3" || subdir=""
    echo -e "\n\e[32mInstalling $1\e[0m\n"
    file_name="$install_dir/$1.tar.gz"
    [[ -f "$file_name" ]] && rm -rf {"$install_dir/$(tar tf "$file_name" | grep -Eom1 "(.*)[^/]")","$file_name"}
    curl "${url_filename}" -o "$file_name"
    tar xf "$file_name" -C "$install_dir"
    mkdir -p "$install_dir/$(tar tf "$file_name" | head -1 | cut -f1 -d"/")${subdir}"
    cd "$install_dir/$(tar tf "$file_name" | head -1 | cut -f1 -d"/")${subdir}"
}
#
download_folder () {
    github_tag="${1}_github_tag"
    url_github="${2}"
    [[ -n "$3" ]] && subdir="/$3" || subdir=""
    echo -e "\n\e[32mInstalling $1\e[0m\n"
    folder_name="$install_dir/$1"
    [[ -d "$folder_name" ]] && rm -rf "$folder_name"
    git ${GIT_PROXY} clone --no-tags --single-branch --branch "${!github_tag}" --shallow-submodules --recurse-submodules -j$(nproc) --depth 1 "${url_github}" "${folder_name}"
    mkdir -p "${folder_name}${subdir}"
    cd "${folder_name}${subdir}"
}
#
## a file deletion function
#
delete_function () {
    if [[ "$SKIP_DELETE" = 'no' ]]; then
        [[ "$2" = 'last' ]] && echo -e "\n\e[91mDeleting $1 installation files and folders\e[0m\n" || echo -e "\n\e[91mDeleting $1 installation files and folders\e[0m"
        #
        file_name="$install_dir/$1.tar.gz"
        folder_name="$install_dir/$1"
        [[ -f "$file_name" ]] && rm -rf {"$install_dir/$(tar tf "$file_name" | grep -Eom1 "(.*)[^/]")","$file_name"}
        [[ -d "$folder_name" ]] && rm -rf "$folder_name"
        cd "$WORKING_DIR"
    else
        [[ "$2" = 'last' ]] && echo -e "\n\e[91mSkipping $1 deletion\e[0m\n" || echo -e "\n\e[91mSkipping $1 deletion\e[0m"
    fi
}
#
application_name () {
    export last_app_name="skip_$app_name"
    export app_name="$1"
    export app_name_skip="skip_$app_name"
    export app_url="${app_name}_url"
    export app_github_url="${app_name}_github_url"
}
#
application_skip () {
    [[ "$1" = 'last' ]] && echo -e "\nSkipping \e[95m$app_name\e[0m module installation\n" || echo -e "\nSkipping \e[95m$app_name\e[0m module installation"
}
#
## Define some URLs to download our apps. They are dynamic and set the most recent version or release.
#
curl_url_data="$HOME/.curl_url_data"
#
export bison_url="http://ftpmirror.gnu.org/gnu/bison/$(curl http://ftpmirror.gnu.org/gnu/bison/ > $curl_url_data && grep -Eo 'bison-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' $curl_url_data | sort -V | tail -1)"
#
export gawk_url="http://ftpmirror.gnu.org/gnu/gawk/$(curl http://ftpmirror.gnu.org/gnu/gawk/ > $curl_url_data && grep -Eo 'gawk-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' $curl_url_data | sort -V | tail -1)"
#
# export glibc_url="http://ftpmirror.gnu.org/gnu/libc/$(curl http://ftpmirror.gnu.org/gnu/libc/ > $curl_url_data && grep -Eo 'glibc-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' $curl_url_data | sort -V | tail -1)"
export glibc_url="http://ftpmirror.gnu.org/gnu/libc/glibc-2.31.tar.gz"
#
export zlib_github_tag="$(curl https://github.com/madler/zlib/releases > $curl_url_data && grep -Eom1 'v1.2.([0-9]{1,2})' $curl_url_data)"
export zlib_url="https://github.com/madler/zlib/archive/$zlib_github_tag.tar.gz"
#
export icu_url="$(curl https://api.github.com/repos/unicode-org/icu/releases/latest > $curl_url_data && grep -Eom1 'ht(.*)icu4c(.*)-src.tgz' $curl_url_data)"
#
export openssl_github_tag="$(curl https://github.com/openssl/openssl/releases > $curl_url_data && grep -Eom1 'OpenSSL_1_1_([0-9][a-z])' $curl_url_data)"
export openssl_url="https://github.com/openssl/openssl/archive/$openssl_github_tag.tar.gz"
#
export boost_version="$(curl https://www.boost.org/users/download/ | sed -rn 's#(.*)e">Version (.*\.[0-9]{1,2})</s(.*)#\2#p')"
export boost_github_tag="boost-$boost_version"
export boost_build_github_tag="boost-$boost_version"
export boost_url="https://dl.bintray.com/boostorg/release/$boost_version/source/boost_${boost_version//./_}.tar.gz"
export boost_url_status="$(curl -o /dev/null --silent --head --write-out '%{http_code}' https://dl.bintray.com/boostorg/release/$boost_version/source/boost_${boost_version//./_}.tar.gz)"
export boost_build_url="https://github.com/boostorg/build/archive/$boost_github_tag.tar.gz"
export boost_github_url="https://github.com/boostorg/boost.git"
#
export qt_version='5.15'
export qtbase_github_tag="$(curl https://github.com/qt/qtbase/releases > $curl_url_data && grep -Eom1 "v$qt_version.([0-9]{1,2})" $curl_url_data)"
export qtbase_github_url="https://github.com/qt/qtbase.git"
export qttools_github_tag="$(curl https://github.com/qt/qttools/releases > $curl_url_data && grep -Eom1 "v$qt_version.([0-9]{1,2})" $curl_url_data)"
export qttools_github_url="https://github.com/qt/qttools.git"
#
export libtorrent_github_url="https://github.com/arvidn/libtorrent.git"
#
export qbittorrent_github_url="https://github.com/qbittorrent/qBittorrent.git"
#
export libtorrent_version='1.2'
if [[ "$GITHUB_TAG" = 'master' ]]; then
    export libtorrent_github_tag="RC_${libtorrent_version//./_}"
else
    export libtorrent_github_tag="$(curl https://github.com/arvidn/libtorrent/releases > $curl_url_data && grep -Eom1 "v$libtorrent_version.([0-9]{1,2})" $curl_url_data)"
fi
#
if [[ "$GITHUB_TAG" = 'master' ]]; then
    export qbittorrent_github_tag="master"
else
    export qbittorrent_github_tag="$(curl https://github.com/qbittorrent/qBittorrent/releases > $curl_url_data && grep -Eom1 'release-([0-9]{1,4}\.?)+' $curl_url_data)"
fi
#
[[ -f "$curl_url_data" ]] && rm -f "$curl_url_data" || :
#
## bison
#
application_name bison
#
if [[ "${!app_name_skip}" = 'no' || "$1" = "$app_name" ]]; then
    custom_flags_reset
    download_file "$app_name" "${!app_url}"
    #
    ./configure --prefix="$install_dir" 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    make -j$(nproc) CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    delete_function "$app_name"
else
    application_skip
fi
#
## gawk
#
application_name gawk
#
if [[ "${!app_name_skip}" = 'no' || "$1" = "$app_name" ]]; then
    custom_flags_reset
    download_file "$app_name" "${!app_url}"
    #
    ./configure --prefix="$install_dir" 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    make -j$(nproc) CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    delete_function "$app_name"
else
    application_skip
fi
#
## glibc static
#
application_name glibc
#
if [[ "${!app_name_skip}" = 'no' || "$1" = "$app_name" ]]; then
    custom_flags_reset
    download_file "$app_name" "${!app_url}"
    #
    mkdir -p build
    cd build
    "$install_dir/$(tar tf "$file_name" | head -1 | cut -f1 -d"/")/configure" --prefix="$install_dir" --enable-static-nss 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    delete_function "$app_name"
else
    application_skip
fi
#
## zlib installation
#
application_name zlib
#
if [[ "${!app_name_skip}" = 'no' || "$1" = "$app_name" ]]; then
    custom_flags_set
    download_file "$app_name" "${!app_url}"
    #
    ./configure --prefix="$install_dir" --static 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    make -j$(nproc) CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    delete_function "$app_name"
else
    application_skip
fi
#
## ICU installation
#
application_name icu
#
if [[ "${!app_name_skip}" = 'no' || "$1" = "$app_name" ]]; then
    custom_flags_set
    download_file "$app_name" "${!app_url}" "/source"
    #
    ./configure --prefix="$install_dir" --disable-shared --enable-static CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    delete_function "$app_name"
else
    application_skip
fi
#
## openssl installation
#
application_name openssl
#
if [[ "${!app_name_skip}" = 'no' || "$1" = "$app_name" ]]; then
    custom_flags_set
    download_file "$app_name" "${!app_url}"
    #
    ./config --prefix="$install_dir" threads no-shared no-dso no-comp CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    make install_sw install_ssldirs 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    delete_function "$app_name"
else
    application_skip
fi
#
## boost build install
#
application_name boost_build
#
if [[ "${!app_name_skip}" = 'no' || "$1" = "$app_name" ]]; then
    custom_flags_set
    download_file "$app_name" "${!app_url}"
    #
    ./bootstrap.sh 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    ./b2 install --prefix="$install_dir" 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    delete_function "$app_name"
else
    application_skip
fi
#
## boost libraries install
#
application_name boost
#
if [[ "${!app_name_skip}" = 'no' ]] || [[ "$1" = "$app_name" ]]; then
    custom_flags_set
    #
    if [[ "$boost_url_status" -eq '200' ]]; then
        download_file "$app_name" "$boost_url"
        mv -f "$install_dir/boost_${boost_version//./_}/" "$install_dir/boost"
        cd "$install_dir/boost"
    fi
    #
    if [[ "$boost_url_status" -eq '403' ]]; then
        download_folder "$app_name" "${!app_github_url}"
    fi
    #
    ./bootstrap.sh 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    "$install_dir/bin/b2" -j$(nproc) python="$python_short_version" variant=release threading=multi link=static cxxstd=14 cxxflags="$CXXFLAGS" cflags="$CPPFLAGS" linkflags="$LDFLAGS" toolset=gcc install --prefix="$install_dir" 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
else
    application_skip
fi
#
## qt base install
#
application_name qtbase
#
if [[ "${!app_name_skip}" = 'no' ]] || [[ "$1" = "$app_name" ]]; then
    custom_flags_set
    download_folder "$app_name" "${!app_github_url}"
    #
    [[ "$SKIP_ICU" = 'no' ]] && icu='-icu' || icu='-no-icu'
    ./configure -prefix "$install_dir" "${icu}" -opensource -confirm-license -release -openssl-linked -static -c++std c++14 -no-feature-c++17 -qt-pcre -no-iconv -no-feature-glib -no-feature-opengl -no-feature-dbus -no-feature-gui -no-feature-widgets -no-feature-testlib -no-compile-examples -I "$include_dir" -L "$lib_dir" QMAKE_LFLAGS="$LDFLAGS" 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    delete_function "$app_name"
else
    application_skip
fi
#
## qt tools install
#
application_name qttools
#
if [[ "${!app_name_skip}" = 'no' ]] || [[ "$1" = "$app_name" ]]; then
    custom_flags_set
    download_folder "$app_name" "${!app_github_url}"
    #
    "$install_dir/bin/qmake" -set prefix "$install_dir" 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    "$install_dir/bin/qmake" QMAKE_CXXFLAGS="-static" QMAKE_LFLAGS="-static" 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    delete_function "$app_name"
else
    application_skip
fi
#
## libtorrent install
#
application_name libtorrent
#
if [[ "${!app_name_skip}" = 'no' ]] || [[ "$1" = "$app_name" ]]; then
    if [[ ! -d "$install_dir/boost" ]]; then
        echo -e "\n\e[91mWarning\e[0m - You must install the boost module before you can use the libtorrent module"
    else
        custom_flags_set
        download_folder "$app_name" "${!app_github_url}"
        #
        export BOOST_ROOT="$install_dir/boost"
        export BOOST_INCLUDEDIR="$install_dir/boost"
        export BOOST_BUILD_PATH="$install_dir/boost"
        #
        "$install_dir/bin/b2" -j$(nproc) python="$python_short_version" dht=on encryption=on crypto=openssl i2p=on extensions=on variant=release threading=multi link=static boost-link=static runtime-link=static cxxstd=14 cxxflags="$CXXFLAGS" cflags="$CPPFLAGS" linkflags="$LDFLAGS" toolset=gcc install --prefix="$install_dir" 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
        #
        delete_function boost
        delete_function "$app_name"
    fi
else
    application_skip
fi
#
## qBittorrent install (static)
#
application_name qbittorrent
#
if [[ "${!app_name_skip}" = 'no' ]] || [[ "$1" = "$app_name" ]]; then
    custom_flags_set
    download_folder "$app_name" "${!app_github_url}"
    #
    ./bootstrap.sh 2>&1 | tee "$install_dir/logs/$app_name.log.txt"
    ./configure --prefix="$install_dir" "$local_boost" --disable-gui CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS -l:libboost_system.a" openssl_CFLAGS="-I$include_dir" openssl_LIBS="-L$lib_dir -l:libcrypto.a -l:libssl.a" libtorrent_CFLAGS="-I$include_dir" libtorrent_LIBS="-L$lib_dir -l:libtorrent.a" zlib_CFLAGS="-I$include_dir" zlib_LIBS="-L$lib_dir -l:libz.a" QT_QMAKE="$install_dir/bin" 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    sed -i 's/-lboost_system//' conf.pri
    sed -i 's/-lcrypto//' conf.pri
    sed -i 's/-lssl//' conf.pri
    #
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt" 
    make install 2>&1 | tee -a "$install_dir/logs/$app_name.log.txt"
    #
    [[ -f "$install_dir/bin/qbittorrent-nox" ]] && cp -f "$install_dir/bin/qbittorrent-nox" "$install_dir/completed/qbittorrent-nox"
    #
    delete_function "$app_name" last
else
    application_skip last
fi
#
## Exit the script.
#
exit
