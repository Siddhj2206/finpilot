export IMAGE_NAME := env("IMAGE_NAME", "finpilot")
export DEFAULT_TAG := env("DEFAULT_TAG", "stable")
export PODMAN := env("PODMAN", "podman")
export REPO_ORG := env("GITHUB_REPOSITORY_OWNER", "projectbluefin")
export bib_image := env("BIB_IMAGE", "ghcr.io/osbuild/bootc-image-builder:latest@sha256:38bfc5efa52c5f24a7953f3e58a9f560a65572fbce40d2fdc2136e0d2a45bd98")

alias build-vm := build-qcow2
alias rebuild-vm := rebuild-qcow2
alias run-vm := run-vm-qcow2

[private]
default:
    @just --list

# Rewrite every justfile in place, or report drift instead when passed --check.
# `check` and `fix` both call this so the file set has one definition.
[private]
_format-justfiles $mode="":
    #!/usr/bin/bash
    set -euo pipefail
    echo "Checking syntax: Justfile"
    just --unstable --fmt {{ mode }} -f Justfile
    while IFS= read -r -d '' file; do
        echo "Checking syntax: ${file}"
        just --unstable --fmt {{ mode }} -f "${file}"
    done < <(find . -type f -name '*.just' -print0)

# Check Just Syntax
[group('Just')]
check:
    just _format-justfiles "--check"

# Run unit tests for build scripts
[group('Just')]
test-unit:
    #!/usr/bin/bash
    set -euo pipefail
    if ! command -v bats &>/dev/null; then
        echo "bats not found — install with: sudo apt-get install bats  OR  npm install -g bats"
        exit 1
    fi
    echo "Running unit tests..."
    # This recipe is the single definition of how the suite runs; CI calls it.
    bats --print-output-on-failure tests/unit/

# Validate Brewfiles without evaluating them as Ruby (see #288)
[group('Just')]
validate-brewfiles:
    #!/usr/bin/bash
    set -euo pipefail
    bash build/validate-brewfiles.sh

# Validate flatpak preinstall files against flathub (Branch= key + app existence)
[group('Just')]
validate-flatpaks:
    #!/usr/bin/bash
    set -euo pipefail
    bash build/validate-flatpaks.sh

# Fix Just Syntax
[group('Just')]
fix:
    just _format-justfiles

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/bash
    set -eoux pipefail
    find . -maxdepth 1 -name '*_build*' -prune -exec rm -rf {} +
    rm -rf output/

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    just sudoif just clean

# sudoif bash function
[group('Utility')]
[private]
sudoif command *args:
    #!/usr/bin/bash
    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        elif [[ "$(command -v sudo)" && -n "${SSH_ASKPASS:-}" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
            /usr/bin/sudo --askpass "$@" || exit 1
        elif [[ "$(command -v sudo)" ]]; then
            /usr/bin/sudo "$@" || exit 1
        else
            exit 1
        fi
    }
    sudoif {{ command }} {{ args }}

# Build the container image with Podman.
#
# Arguments:
#   $target_image - the image to build (default: $IMAGE_NAME)
#   $tag          - the image tag (default: $DEFAULT_TAG)
#
# The version string is <fedora-major>.<date> for a tag containing "stable" and
# <tag>-<fedora-major>.<date> otherwise. The Fedora major comes from the
# Containerfile, a point release is appended when the registry already has that
# version, and a clean worktree also stamps the short HEAD SHA.
#
# Example: just build finpilot stable-testing

# Build the image using the specified parameters
[group('Image')]
build $target_image=IMAGE_NAME $tag=DEFAULT_TAG:
    #!/usr/bin/env bash

    # Read the Fedora major version from Containerfile (single source of truth).
    # The base image itself is pinned in the Containerfile FROM line.
    fedora_version=$(grep -E '^ARG FEDORA_MAJOR_VERSION=' Containerfile | head -n1 | sed -E 's/^ARG FEDORA_MAJOR_VERSION="?([^"]+)"?/\1/')
    if [[ -z "${fedora_version:-}" ]]; then
        echo "ERROR: Could not extract FEDORA_MAJOR_VERSION from Containerfile"
        exit 1
    fi

    # Image identity, resolved once: an explicit IMAGE_VENDOR wins, otherwise
    # fall back to the repository owner GitHub Actions supplies.
    image_vendor="${IMAGE_VENDOR:-${REPO_ORG}}"

    # Bluefin-style version string: <fedora-version>.<date> for stable,
    # <tag>-<fedora-version>.<date> for everything else.
    if [[ "${tag}" =~ stable ]]; then
        ver="${fedora_version}.$(date +%Y%m%d)"
    else
        ver="${tag}-${fedora_version}.$(date +%Y%m%d)"
    fi

    # Avoid tag collisions when rebuilding on the same day
    if command -v skopeo &>/dev/null; then
        repotags=$(mktemp -t repotags.XXXXXXXX.json) || { echo "ERROR: mktemp failed to create tag-list temp file"; exit 1; }
        trap 'rm -f "${repotags}"' EXIT
        skopeo list-tags "docker://ghcr.io/${image_vendor}/${target_image}" >"${repotags}" 2>/dev/null \
            || echo '{"Tags":[]}' >"${repotags}"
        if [[ $(jq "any(.Tags[]; contains(\"${ver}\"))" "${repotags}") == "true" ]]; then
            POINT=1
            while [[ $(jq "any(.Tags[]; contains(\"${ver}.${POINT}\"))" "${repotags}") == "true" ]]; do
                ((POINT++))
            done
            ver="${ver}.${POINT}"
            echo "Tag collision detected; using version ${ver}"
        fi
    fi

    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "VERSION=${ver}")
    if [[ -z "$(git status -s)" ]]; then
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi

    # Image identity ARGs - these define how bootc/ublue ecosystem recognizes the image.
    # Override via env vars: IMAGE_NAME, IMAGE_VENDOR, UBLUE_IMAGE_TAG
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME=${target_image}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR=${image_vendor}")
    BUILD_ARGS+=("--build-arg" "UBLUE_IMAGE_TAG=${UBLUE_IMAGE_TAG:-${tag}}")

    # The Containerfile owns the OCI/ArtifactHub metadata, including URLs
    # derived from image identity. Pass only explicit metadata overrides.
    BUILD_ARGS+=("--build-arg" "IMAGE_CREATED=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)")
    for metadata_arg in IMAGE_DESC IMAGE_LOGO_URL IMAGE_KEYWORDS IMAGE_REF; do
        if [[ -n "${!metadata_arg:-}" ]]; then
            BUILD_ARGS+=("--build-arg" "${metadata_arg}=${!metadata_arg}")
        fi
    done

    # Add GitHub token as build secret if available (for CI/CD)
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "Adding GitHub token as build secret"
        BUILD_ARGS+=("--secret" "id=GITHUB_TOKEN,env=GITHUB_TOKEN")
    fi

    # Registry layer cache - speeds up rebuilds by reusing unchanged layers from GHCR
    # CI sets REGISTRY_CACHE_WRITE=1 for candidate builds; local builds stay
    # read-only so a developer never poisons the shared cache
    CACHE_ARGS=()
    cache_ref="ghcr.io/${image_vendor}/${target_image}"
    if skopeo list-tags "docker://${cache_ref}" >/dev/null 2>&1; then
        CACHE_ARGS+=("--cache-from" "${cache_ref}")
        if [[ "${REGISTRY_CACHE_WRITE:-0}" == "1" ]]; then
            CACHE_ARGS+=("--cache-to" "${cache_ref}")
        fi
    fi

    ${PODMAN} build \
        "${BUILD_ARGS[@]}" \
        "${CACHE_ARGS[@]}" \
        --pull=newer \
        --tag "${target_image}:${tag}" \
        .

# Tag images with the generated alias tags
# Bluefin pattern: separate tagging from pushing
[group('Image')]
tag-images $image_name="" $default_tag="" $tags="":
    #!/usr/bin/bash
    set -eou pipefail

    if [[ -z "${image_name}" || -z "${default_tag}" || -z "${tags}" ]]; then
        echo "Usage: just tag-images <image_name> <default_tag> <tags>"
        exit 1
    fi

    IMAGE=$(${PODMAN} inspect "localhost/${image_name}:${default_tag}" | jq -r '.[].Id')
    ${PODMAN} untag "localhost/${image_name}:${default_tag}"

    for tag in ${tags}; do
        ${PODMAN} tag "${IMAGE}" "${image_name}:${tag}"
    done

    # Re-apply default tag so local operations can still find it
    ${PODMAN} tag "${IMAGE}" "${image_name}:${default_tag}"

    echo "Tagged ${image_name} with: ${tags}"

# Make the locally built image visible to rootful podman so Bootc Image Builder
# can read it, copying it across with `podman image scp`. Falls back to pulling
# it from the registry when it only exists there, and no-ops when already root.

_rootful_load_image $target_image=IMAGE_NAME $tag=DEFAULT_TAG:
    #!/usr/bin/bash
    set -eoux pipefail

    # Check if already running as root or under sudo
    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
        echo "Already root or running under sudo, no need to load image from user podman."
        exit 0
    fi

    # Try to resolve the image tag using podman inspect
    set +e
    resolved_tag=$(podman inspect -t image "${target_image}:${tag}" | jq -r '.[].RepoTags.[0]')
    return_code=$?
    set -e

    USER_IMG_ID=$(podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")

    if [[ $return_code -eq 0 ]]; then
        # If the image is found, load it into rootful podman
        ID=$(just sudoif podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")
        if [[ "$ID" != "$USER_IMG_ID" ]]; then
            # If the image ID is not found or different from user, copy the image from user podman to root podman
            COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
            just sudoif TMPDIR=${COPYTMP} podman image scp ${UID}@localhost::"${target_image}:${tag}" root@localhost::"${target_image}:${tag}"
            rm -rf "${COPYTMP}"
        fi
    else
        # If the image is not found, pull it from the repository
        just sudoif podman pull "${target_image}:${tag}"
    fi

# Convert a container image into a bootable disk with Bootc Image Builder.
# type is qcow2, raw or iso; config is the BIB config file to use
# (iso/disk.toml for qcow2 and raw, iso/iso.toml for iso).
_build-bib $target_image $tag $type $config: (_rootful_load_image target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail

    args="--type ${type} "
    args+="--use-librepo=True "
    args+="--rootfs=btrfs"

    # Bootc Image Builder records the post-install `bootc switch` origin from
    # the image reference it is given, so an ISO has to be built against the
    # published reference instead of the local build tag. The image names
    # itself in image-info.json, which keeps one source of truth for forks and
    # means iso/iso.toml carries no image reference at all.
    build_image="${target_image}:${tag}"
    if [[ "${type}" == "iso" ]]; then
        image_info=$(just sudoif podman run --rm --entrypoint /usr/bin/cat \
            "${target_image}:${tag}" /usr/share/ublue-os/image-info.json)
        image_ref=$(jq -r '."image-ref"' <<<"${image_info}" | sed 's|.*docker://||')
        build_image="${image_ref}:$(jq -r '."image-tag"' <<<"${image_info}")"
        just sudoif podman tag "${target_image}:${tag}" "${build_image}"
    fi

    BUILDTMP=$(mktemp -p "${PWD}" -d -t _build-bib.XXXXXXXXXX)

    sudo podman run \
      --rm \
      -it \
      --privileged \
      --pull=newer \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v $(pwd)/${config}:/config.toml:ro \
      -v $BUILDTMP:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      ${args} \
      "${build_image}"

    mkdir -p output
    sudo mv -f $BUILDTMP/* output/
    sudo rmdir $BUILDTMP
    sudo chown -R $USER:$USER output/

# Rebuild the container image first, then convert it (see _build-bib).
_rebuild-bib $target_image $tag $type $config: (build target_image tag) && (_build-bib target_image tag type config)

# Build a QCOW2 virtual machine image
[group('Build Virtual Machine Image')]
build-qcow2 $target_image=("localhost/" + IMAGE_NAME) $tag=DEFAULT_TAG: && (_build-bib target_image tag "qcow2" "iso/disk.toml")

# Build a RAW virtual machine image
[group('Build Virtual Machine Image')]
build-raw $target_image=("localhost/" + IMAGE_NAME) $tag=DEFAULT_TAG: && (_build-bib target_image tag "raw" "iso/disk.toml")

# Build an ISO virtual machine image
[group('Build Virtual Machine Image')]
build-iso $target_image=("localhost/" + IMAGE_NAME) $tag=DEFAULT_TAG: && (_build-bib target_image tag "iso" "iso/iso.toml")

# Rebuild a QCOW2 virtual machine image
[group('Build Virtual Machine Image')]
rebuild-qcow2 $target_image=("localhost/" + IMAGE_NAME) $tag=DEFAULT_TAG: && (_rebuild-bib target_image tag "qcow2" "iso/disk.toml")

# Rebuild a RAW virtual machine image
[group('Build Virtual Machine Image')]
rebuild-raw $target_image=("localhost/" + IMAGE_NAME) $tag=DEFAULT_TAG: && (_rebuild-bib target_image tag "raw" "iso/disk.toml")

# Rebuild an ISO virtual machine image
[group('Build Virtual Machine Image')]
rebuild-iso $target_image=("localhost/" + IMAGE_NAME) $tag=DEFAULT_TAG: && (_rebuild-bib target_image tag "iso" "iso/iso.toml")

# Run a virtual machine with the specified image type and configuration
_run-vm $target_image $tag $type $config:
    #!/usr/bin/bash
    set -eoux pipefail

    # Determine the image file based on the type
    image_file="output/${type}/disk.${type}"
    if [[ $type == iso ]]; then
        image_file="output/bootiso/install.iso"
    fi

    # Build the image if it does not exist
    if [[ ! -f "${image_file}" ]]; then
        just "build-${type}" "$target_image" "$tag"
    fi

    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_file}":"/boot.${type}")
    run_args+=(docker.io/qemux/qemu)

    # Run the VM and open the browser to connect
    (sleep 30 && xdg-open http://localhost:"$port") &
    podman run "${run_args[@]}"

# Run a virtual machine from a QCOW2 image
[group('Run Virtual Machine')]
run-vm-qcow2 $target_image=("localhost/" + IMAGE_NAME) $tag=DEFAULT_TAG: && (_run-vm target_image tag "qcow2" "iso/disk.toml")

# Run a virtual machine from a RAW image
[group('Run Virtual Machine')]
run-vm-raw $target_image=("localhost/" + IMAGE_NAME) $tag=DEFAULT_TAG: && (_run-vm target_image tag "raw" "iso/disk.toml")

# Run a virtual machine from an ISO
[group('Run Virtual Machine')]
run-vm-iso $target_image=("localhost/" + IMAGE_NAME) $tag=DEFAULT_TAG: && (_run-vm target_image tag "iso" "iso/iso.toml")

# Run a virtual machine using systemd-vmspawn
[group('Run Virtual Machine')]
spawn-vm rebuild="0" type="qcow2" ram="6G":
    #!/usr/bin/env bash

    set -euo pipefail

    if [[ "{{ rebuild }}" -eq 1 ]]; then
        echo "Rebuilding the {{ type }} image"
        just "build-{{ type }}"
    fi

    systemd-vmspawn \
      -M "bootc-image" \
      --console=gui \
      --cpus=2 \
      --ram=$(echo {{ ram }}| /usr/bin/numfmt --from=iec) \
      --network-user-mode \
      --vsock=false --pass-ssh-key=false \
      -i ./output/**/*.{{ type }}

# The repository's shell scripts: the *.sh files git tracks. Single definition
# of the lint and format scope, and of the glob CI hands to validate-pr.
[private]
shell-sources:
    #!/usr/bin/env bash
    set -euo pipefail
    git ls-files '*.sh'

# Runs shell check on the shell scripts git tracks
[group('Just')]
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    # Check if shellcheck is installed
    if ! command -v shellcheck &> /dev/null; then
        echo "shellcheck could not be found. Please install it."
        exit 1
    fi
    # git is the single source of truth for lint scope; CI resolves the same
    # list into validate-pr's shellcheck-glob input.
    mapfile -t sources < <(just shell-sources)
    if [[ ${#sources[@]} -eq 0 ]]; then
        echo "No shell scripts found: git tracks no *.sh files" >&2
        exit 1
    fi
    printf 'Shellchecking %s scripts:\n' "${#sources[@]}"
    printf '  %s\n' "${sources[@]}"
    shellcheck "${sources[@]}"

# Runs shfmt on the shell scripts git tracks
[group('Just')]
format:
    #!/usr/bin/env bash
    set -euo pipefail
    # Check if shfmt is installed
    if ! command -v shfmt &> /dev/null; then
        echo "shfmt could not be found. Please install it."
        exit 1
    fi
    # Format exactly the files lint checks.
    mapfile -t sources < <(just shell-sources)
    if [[ ${#sources[@]} -eq 0 ]]; then
        echo "No shell scripts found: git tracks no *.sh files" >&2
        exit 1
    fi
    printf 'Formatting %s scripts:\n' "${#sources[@]}"
    printf '  %s\n' "${sources[@]}"
    shfmt --write "${sources[@]}"
