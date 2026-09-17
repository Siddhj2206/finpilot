# custom/config

Per-user configuration, seeded into the `~/.config/` of every new user.

Files here are copied to `/etc/skel/.config/` at build time, so accounts created
after the build start with them. Existing users are deliberately left alone:
rewriting a home directory on every boot would discard their edits, so updating
a user who already exists is a `ujust` command, never an automatic login hook.

This is the last step in the overlay order in `build/10-overlay.sh`
(`common/shared`, `ublue-os/brew`, `custom/files`, then this one), so a file here
also wins over an inherited one — including the `/etc/skel/.config/` files that
`common/shared` ships. Overriding that way is intended.

Use `custom/files/` instead for system payloads outside `~/.config/`, such as
systemd units, presets, and tmpfiles.d entries.

`environment.d/10-example.conf` is the shipped example: inert as written, and
safe to replace with your own configuration.
