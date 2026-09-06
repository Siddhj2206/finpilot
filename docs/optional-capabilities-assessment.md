# Optional Capability Assessment

**Decision-ticket evidence for:** [Verify optional template capabilities against current upstream](https://github.com/Siddhj2206/finpilot/issues/4)
**Upstream reference:** [`projectbluefin/bluefin@c442e5c`](https://github.com/projectbluefin/bluefin/tree/c442e5c46f6d3a0e95dda5b1d6794dc7f56906ae)

## Result

Keep every current capability as an intended outcome where it remains viable,
but do not preserve each example script's implementation. The examples are
currently inconsistent in reliability and do not fit the shared-overlay
dependencies identified in the common-overlay assessment.

The default Fedora Silverblue/GNOME reference image remains unchanged. The
rewrite should turn viable optional capabilities into documented, tested
activation paths and replace destructive or hardcoded examples with a current
equivalent.

## Build examples

| Capability | Current state | Current upstream pattern | Decision | Required validation |
| --- | --- | --- | --- | --- |
| Third-party RPM applications: Chrome and 1Password | **Broken as written.** The unquoted `$basearch` in a `set -u` script is expanded by the shell while writing the repo file, so activation fails before package installation. It also combines two unrelated vendors in one example. | Bluefin uses isolated repository setup/cleanup and explicit build stages. | Preserve third-party RPM installation as a generic, security-focused pattern. Replace this script with independent examples or one generic helper that uses signed repository metadata, temporary repo files, and no runtime repo persistence. | ShellCheck; an activated image-build smoke test; assert repo files are absent afterward. |
| COSMIC desktop | Not a viable in-place desktop swap. It removes GNOME/GDM but shared Finpilot functionality will rely on GNOME dconf, setup hooks, extensions, and GNOME-oriented defaults. The COPR package set is also an external moving dependency. | Bluefin is a GNOME product and does not offer this as an in-place variant. Its architecture separates image assembly and overlays by variant. | Preserve the ability to build a COSMIC-based image, but replace the destructive script with a separately documented alternate-base/desktop path. It must select a compatible base and its own runtime substrate rather than mutate the GNOME reference image. | Build the alternate image; boot it; verify its display manager and a minimal desktop session. |
| NVIDIA drivers and container toolkit | Viable intent, but the example is a partial older form of Bluefin's kernel/akmods installation logic. It does not include `common/nvidia`'s Flatpak-runtime synchronization service. | Bluefin's [`04-install-kernel-akmods.py`](https://github.com/projectbluefin/bluefin/blob/c442e5c46f6d3a0e95dda5b1d6794dc7f56906ae/build_files/base/04-install-kernel-akmods.py) resolves kernel-matched akmods artifacts, configures NVIDIA, and validates required packages. | Preserve NVIDIA as a first-class optional image variant. Rebase its driver install on the current upstream approach and pair it with `common/nvidia`, rather than retain a standalone example. | Image build; package assertions; boot/driver smoke test; verify NVIDIA Flatpak runtime-sync is conditional and enabled. |

## Local artifact and VM capabilities

| Capability | Current state | Direction | Required validation |
| --- | --- | --- | --- |
| QCOW2 and RAW from bootc-image-builder | Viable and useful local author workflow. The recipes use a digest-pinned bootc-image-builder input. | Retain. Simplify only after keeping the existing command names or documenting migration. | Build each artifact and verify expected output exists. |
| ISO from bootc-image-builder | Viable goal but unsafe/unforkable configuration: `iso/iso.toml` hardcodes `ghcr.io/projectbluefin/finpilot:stable` and its kickstart does not enforce the container signature policy. | Retain ISO support, but generate/pass the fork's actual image reference and use signature enforcement. Bluefin's current container-native ISO stage derives its install reference from `image-info.json` and performs `bootc switch --enforce-container-sigpolicy`; that is the pattern to adapt. | Build an ISO from a renamed fork; inspect kickstart/reference; install/boot smoke test; verify signed image switch. |
| QEMU runner | Useful local smoke path, but currently pulls floating `docker.io/qemux/qemu` at runtime. | Retain with a digest-pinned, Renovate-tracked QEMU image and explicit host requirements. | Start a built QCOW2 and confirm the exposed console endpoint. |
| `systemd-vmspawn` runner | Useful faster host-native alternative, contingent on a compatible host. | Retain as a conditional advanced path, not the only VM route. | Detect `systemd-vmspawn` and KVM first; boot a QCOW2; report a precise prerequisite error when unavailable. |

## Detailed NVIDIA note

The current Bluefin implementation does more than the Finpilot example:

1. resolves the current Fedora/kernel-specific `ublue-os/akmods` and
   `akmods-nvidia-open` OCI artifacts;
2. installs and version-locks a matching kernel package set;
3. installs NVIDIA packages, boot arguments, and NVIDIA Container Toolkit; and
4. validates expected NVIDIA packages during the image build.

Finpilot should reuse this behavior as a **pattern**, not copy Bluefin's
multi-flavor factory wholesale. The template decision is its small interface:
an explicitly activated NVIDIA image variant with a documented supported
base/kernel combination. The implementation must include the paired
`common/nvidia` overlay selected in the common assessment.

## Implications for template usability

The current activation rule—rename a `.example` file and manually insert a
matching Containerfile `RUN` instruction—is explicit but error-prone. Keep
Containerfile as the visible assembly authority, while making activation
mechanical:

1. examples state their supported base, required overlay, packages, and tests;
2. the relevant Containerfile block is adjacent and clearly marked;
3. a validation checks that an activated capability has every required
   Containerfile stage/overlay/service; and
4. first-class variants such as NVIDIA gain a named build command and smoke
   test rather than relying on a copy-and-edit example.

This preserves the capabilities without forcing a new metadata file or hiding
critical image behavior outside the Containerfile.
