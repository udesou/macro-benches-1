# Dashboard — to be built

The static dashboard export for this run is **not yet committed**. It is produced
outside this repo from the Observable Framework app
[`ghcr.io/udesou/ocaml-bench-dashboard`](https://github.com/udesou/ocaml-bench-dashboard),
built against this run's `../logs/` (sidecars + `olly.ndjson` / `perf.ndjson`).

The **native data contract** for this run is committed at
[`../logs/contract/`](../logs/contract/) — `manifest.json` (schema 1.0,
38 benchmarks, 4 configs, the fp/flambda-vs-stock comparison) plus
`measurements/{olly,perf}.ndjson` (760 invocations each). Point the dashboard
build at that so it renders in **native** mode rather than legacy.

To add the static export:

1. Build/point the dashboard image at this run's native contract
   [`../logs/contract/`](../logs/contract/) (equivalently the original run dir
   `~/running-ng/gc-sweep-logs-5.5.0-fp-flambda-ermine-2026-08-20/ermine-2026-08-20-Thu-053154/contract/`).
2. Export the static site and commit it here, replacing this README, so it
   survives the registry tag — mirroring
   [`../../2026-07-24-5.5.0-fp-flambda-monolith/dashboard/`](../../2026-07-24-5.5.0-fp-flambda-monolith/dashboard/).

It is an ES-module app, so `file://` will not load it — serve the directory:
`cd dashboard && python3 -m http.server 8080`, or
`docker run --rm -p 8080:80 ghcr.io/udesou/ocaml-bench-dashboard:<tag>`.

(This placeholder exists so the results package keeps the same four-subdirectory
structure — `dashboard/`, `logs/`, `notebooks/`, `report/` — as the other runs
under `results/latest/`.)
