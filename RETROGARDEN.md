# RetroGarden packaging notes

**Public corresponding source:** https://github.com/vinybrun/retrogarden-retrospring

This directory is a **fork** of [Retrospring/retrospring](https://github.com/Retrospring/retrospring) (AGPLv3), packaged for multi-instance hosting by **RetroGarden**.

RetroGarden is an independent product and is **not affiliated with, endorsed by, or the official operator of** the original Retrospring project or retrospring.net.

## Hosting additions

- `Dockerfile` — production image built from this tree
- `docker/entrypoint.sh` — `web` | `sidekiq` | `migrate` | `admin`
- `docker/generate-justask-yml.sh` — fallback config from env
- Extended `lib/retrospring/config.rb` — more ENV overrides

## Versioning

RetroGarden pins a platform image tag (e.g. `retrogarden/retrospring:2026.7.18-rg.1`).
All tenant instances run the same tag; the control plane rolls updates.
Every production image tag must map to a **public** git tag on
https://github.com/vinybrun/retrogarden-retrospring — see monorepo `docs/SOURCE.md`.

## AGPL

Upstream license is AGPLv3. Modifications in this tree must remain available
to network users of hosted instances via the public repository above.
