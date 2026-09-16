# Finpilot

Finpilot is a forkable bootc image template for people and agents building
custom operating systems on Project Bluefin infrastructure. This glossary
preserves the product terms that guide its rewrite.

## Language

**Finpilot**:
A full-featured, customizable bootc image template. It is smaller in scope than
the Bluefin product, but it does not remove an existing capability without a
clear, documented reason.
_Avoid_: Minimal template, Bluefin clone

**Template user**:
A human or agent who forks Finpilot and shapes an image for a specific use.
The template must expose its choices clearly enough that either can work safely.
_Avoid_: Consumer, end user

**Default path**:
The documented, validated route through the template for a new image author.
It prioritizes discoverability and safe guided operations; advanced
configuration may remain available as explicit opt-in capability.
_Avoid_: Minimal feature set, only supported configuration

**Compatibility**:
Best-effort continuity for an existing Finpilot fork. Preserve an author-facing
seam when practical, but do not guarantee it at the cost of retaining obsolete
or unnecessarily complex implementation.
_Avoid_: Compatibility guarantee, internal implementation preservation

**Reference image**:
The unmodified template's Fedora Silverblue/GNOME image with Brew, Flatpak,
ujust, local artifact, and signed-GHCR support. It is the default example
against which template usability is judged.
_Avoid_: Minimal image, Bluefin product

**Two-branch release model**:
Finpilot's supported `main` to `stable` promotion and `stable` to `main` sync
model. It remains a template capability, although its workflow implementation
and setup may be redesigned.
_Avoid_: Optional release profile, immutable implementation

**Candidate digest**:
The immutable, keylessly signed image digest published from `main` as
`:testing`. A stable release promotes this exact digest rather than rebuilding
the same source on `stable`.
_Avoid_: Rebuilt stable artifact, mutable testing tag

**Explanatory Containerfile**:
Finpilot's visible image-assembly source of truth. It is intentionally
well-commented and structurally explicit so regular users and agents can
understand and safely change it; reducing duplicated configuration must not
make it terse or opaque.
_Avoid_: Clever minimal Dockerfile, hidden template configuration

**Shared overlay**:
Selected runtime content from `projectbluefin/common`'s `shared/` and
`nvidia/` layers. A selected item may be a default dependency or an explicit
opt-in, and its relationship to `bluefin/` must be documented.
_Avoid_: Whole common layer, Bluefin feature

**Bluefin factory**:
The Project Bluefin production product and its release infrastructure. It is a
source of patterns and shared infrastructure, not the feature baseline that
Finpilot must duplicate.
_Avoid_: Template dependency
