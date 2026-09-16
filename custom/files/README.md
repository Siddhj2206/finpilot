# custom/files

System files that are overlaid onto the image root (`/`).

The directory tree under `custom/files/` mirrors the image filesystem, so a file
placed at `custom/files/usr/lib/systemd/system/foo.service` lands at
`/usr/lib/systemd/system/foo.service`. Use it for systemd units, presets,
tmpfiles.d entries, sysusers.d entries, and other system payloads the template
ships by default.

This is not a user-configuration seam. For new-user config use `custom/config/`,
for runtime packages use `custom/brew/`, and for commands use `custom/ujust/`.
