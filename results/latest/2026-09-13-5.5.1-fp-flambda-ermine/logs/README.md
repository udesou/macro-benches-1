# 2026-09-13 5.5.1 fp/flambda ermine — sidecar logs

Per-invocation sidecar data from the 5.5.1 `-fp`/`-flambda` sweep on **ermine**
(aarch64).

**Contents**

- `olly_<bench>.0.0.<runtime>.perf_grp1.macro-<repo>.json` — JSONL, **one JSON object per invocation**. Fields: `wall_time`, `cpu_time`, `gc_time`, `gc_overhead`, `max_rss_kb`, `allocations.*`, `collections.*`, `mean_latency`, `distr_latency`, `domain_stats`.
- `perf_<bench>....json` — JSONL, one per invocation. `perf stat`: `task-clock`, `page-faults`, `cycles`, `instructions`.
- `olly.ndjson` / `perf.ndjson` — the run-level contract measurement streams (one line per invocation; 840 lines each).
- `contract/` — native data contract (`manifest.json` schema 1.0 + `measurements/{olly,perf}.ndjson`), for the dashboard's native mode.
- `runbms.yml` — resolved config (post-includes, post-overrides). What actually ran.
- `runbms_args.yml` — the CLI args running-ng was invoked with.

The stdout `.log` files are **not** mirrored here (large, no analysis-relevant
data beyond the sidecars). Original run dir:
`~/running-ng/gc-sweep-logs-5.5.1-fp-flambda-ermine-2026-09-13/ermine-2026-09-13-Sun-104353/`

**Run parameters**

- Host: ermine (ARM **Neoverse-N1**, 80 cores / 1 thread-per-core, governor=performance, 250 GiB, kernel 6.8.0-90-generic)
- Compilers: `ocaml-5.5.1` (from the `ocaml/ocaml` `5.5.1` tag) built stock / `--enable-frame-pointers` / `--enable-flambda` / both
- Tools: olly `0.5.4-12-g3d37a0b`, perf `6.8.12`; running-ng
- **42 benchmarks × 4 variants × N=5 — 840 invocations** (168 cells, 168 sidecar pairs)
- Run started 2026-09-13, finished 2026-09-15

**Full ladder — goblint included.** Unlike the 2026-08-20 5.5.0 run (which
dropped `goblint_gen_{default,large}`), this run has **all 42** default+large
programs, including goblint and the new `infer`. goblint required two
aarch64-only fixes now on master: apron's MPFR built from source when the box
lacks `libmpfr-dev` (PR #27), and goblint's x86-only `-m64` cpp flag guarded off
on aarch64 (PR #27); devkit's libevent path was also made multiarch (PR #26).

**Allocation counters are clean here (in words).** Measured
`minor_words / minor_collections` = 1.00 × the minor-heap size, so `minor_words`,
`promoted_words`, `total_heap_words` and derived metrics are correct (olly
`0.5.4-12-g3d37a0b` reports words, not the bytes of the 2026-07-24 run).
