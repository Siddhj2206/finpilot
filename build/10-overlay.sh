#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Runtime overlays
###############################################################################
# This phase owns every runtime integration the image applies on top of its
# base: the selected Common and Brew filesystem overlays, the template's custom
# declaration seams, and the systemd enablement that makes those declarations
# live.
#
# It installs nothing. RPM and COPR installation belongs to
# 20-packages-and-services.sh.
#
# See docs/common-overlay-assessment.md for why only Common's shared/ layer is
# overlaid: shared/ is reusable runtime infrastructure, bluefin/ is product
# opinion, and nvidia/ is a paired hardware feature that must ship with a real
# driver installation.
###############################################################################

shopt -s nullglob

echo "::group:: Overlay shared Common runtime files"

# Shared runtime substrate: the ujust entry point and wrapper, first-boot setup
# hooks, container trust policy, and the Flatpak/Brew declarations these
# services consume.
rsync -rvK /ctx/oci/common/shared/ /

echo "::endgroup::"

echo "::group:: Overlay Brew integration files"

# Brew supplies the Homebrew mechanism (archive, systemd units, shell
# integration). The template supplies the package declarations below.
rsync -rvK /ctx/oci/brew/ /

echo "::endgroup::"

echo "::group:: Overlay template system files"

# custom/files mirrors the image root, so a fork can ship systemd units,
# presets, and other system payloads by path.
rsync -rvKl /ctx/custom/files/ /

echo "::endgroup::"

echo "::group:: Copy template custom declarations"

# custom/config seeds each new user's ~/.config. Updating users who already
# exist is a deliberate, idempotent ujust command, never an automatic login hook.
if [[ -d /ctx/custom/config ]]; then
	mkdir -p /etc/skel/.config
	cp -a /ctx/custom/config/. /etc/skel/.config/
fi

# Brewfiles consumed by first-user Homebrew setup.
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Merge custom ujust recipes into the file the shared ujust entry point imports.
# Sort the inputs and write one blank line between them so the merged result is
# deterministic and idempotent.
mkdir -p /usr/share/ublue-os/just/
: >/usr/share/ublue-os/just/60-custom.just
recipes=(/ctx/custom/ujust/*.just)
if ((${#recipes[@]})); then
	while IFS= read -r recipe; do
		cat "${recipe}" >>/usr/share/ublue-os/just/60-custom.just
		printf '\n' >>/usr/share/ublue-os/just/60-custom.just
	done < <(printf '%s\n' "${recipes[@]}" | LC_ALL=C sort)
fi

# Flatpak preinstall declarations, consumed at first boot.
mkdir -p /usr/share/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /usr/share/flatpak/preinstall.d/

echo "::endgroup::"

echo "::group:: Enable runtime services"

# Units the overlays above provide. Enabling them here is what makes the Brew
# and Flatpak declarations take effect, and it matches how Bluefin's cleanup
# phase wires the same shared services.
systemctl enable brew-setup.service
systemctl enable brew-update.timer
systemctl enable brew-upgrade.timer
systemctl --global enable brew-preinstall.service
systemctl enable flatpak-preinstall.service
systemctl enable flatpak-appstream-refresh.service
# Adds the Flathub remote on first boot; build-time remote state cannot live in
# /var (bootc lint rejects it) and flatpak does not read /etc/flatpak/remotes.d.
systemctl enable flatpak-add-flathub-repos.service

# First-boot setup framework.
systemctl enable ublue-system-setup.service
systemctl --global enable ublue-user-setup.service

# Rootless container management for the reference image.
systemctl enable podman.socket

echo "::endgroup::"

shopt -u nullglob

echo "Overlay phase complete!"
