# F-Droid Privileged Extension locked-module wiring

The F-Droid Privileged Extension integration is disabled by default. PixeneOS
does not currently ship an approved production artifact lock or ROM profile,
so enabling the flag without adding reviewed inputs fails closed.

After an artifact lock and profile have been independently reviewed and
committed to this repository, the local configuration surface is:

```toml
ADDITIONALS_FDROID_PRIVILEGED_EXTENSION = true
FDROID_PRIVILEGED_EXTENSION_LOCK = "path/to/artifacts.lock.json"
FDROID_PRIVILEGED_EXTENSION_PROFILE = "path/to/profile.toml"
```

The lock and profile must be regular, non-symlink files inside the checkout,
tracked by Git, and byte-identical to their versions in `HEAD`. Optional
`FDROID_PRIVILEGED_EXTENSION_CACHE` and
`FDROID_PRIVILEGED_EXTENSION_PATCH_REPORT` values select local cache and report
paths. The cache defaults under `.tmp`; the report defaults next to the patched
OTA as `<patched-output>.patch-report.json` so ordinary work-directory cleanup
does not discard the audit record.

When enabled, PixeneOS asks the pinned helper to resolve the profile before any
network fetch, fetch only the locked module artifacts, verify them, and finally
passes the lock, profile, cache, and report paths to the patch command. Artifact
URLs and versions are never declared in Bash, and the module does not use the
legacy ZIP/signature preflight.
