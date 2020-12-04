#!/bin/bash

set -e

function print_info() {
    echo -e "\e[36mINFO: ${1}\e[m"
}

wget https://repo.anaconda.com/miniconda/Miniconda3-latest-linux-x86_64.sh -O miniconda.sh
bash miniconda.sh -b -p "$HOME"/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
source "$HOME"/miniconda/etc/profile.d/conda.sh

# set configs
conda config --set always_yes yes --set changeps1 no
conda config --add channels conda-forge
conda config --set channel_priority strict
conda config --append channels jrgarrahan # temporary lume-model fix
conda install conda-build anaconda-client
conda update -q conda conda-build

# log info for debugging
conda info -a

# create build & add to channel
conda build -q conda-recipe --python=3.7 --output-folder bld-dir
conda config --add channels "file://`pwd`/bld-dir"

# create env
conda create -q -n test-environment python=3.7 --file dev-requirements.txt
conda activate test-environment
conda install --file docs-requirements.txt

if [ -n "${CUSTOM_DOMAIN}" ]; then
    print_info "Setting custom domain for github pages"
    echo "${CUSTOM_DOMAIN}" > "${GITHUB_WORKSPACE}/docs/CNAME"
fi

if [ -n "${CONFIG_FILE}" ]; then
    print_info "Setting custom path for mkdocs config yml"
    export CONFIG_FILE="${GITHUB_WORKSPACE}/${CONFIG_FILE}"
else
    export CONFIG_FILE="${GITHUB_WORKSPACE}/mkdocs.yml"
fi

if [ -n "${GITHUB_TOKEN}" ]; then
    print_info "setup with GITHUB_TOKEN"
    remote_repo="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
elif [ -n "${PERSONAL_TOKEN}" ]; then
    print_info "setup with PERSONAL_TOKEN"
    remote_repo="https://x-access-token:${PERSONAL_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
fi

if ! git config --get user.name; then
    git config --global user.name "${GITHUB_ACTOR}"
fi

if ! git config --get user.email; then
    git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
fi

git remote rm origin
git remote add origin "${remote_repo}"

mkdocs gh-deploy --config-file "${CONFIG_FILE}" --force
