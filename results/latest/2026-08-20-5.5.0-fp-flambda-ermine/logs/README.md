# 2026-08-20 5.5.0 fp/flambda ermine — sidecar logs

Per-invocation sidecar data from the 08-20 `-fp`/`-flambda` sweep on **ermine**
(aarch64). See the report:
[../report/2026-08-20-5.5.0-fp-flambda-ermine.md](../report/2026-08-20-5.5.0-fp-flambda-ermine.md).

**Contents**

- `olly_<bench>.0.0.<runtime>.perf_grp1.macro-<repo>.json` — JSONL, **one JSON object per invocation**. Fields: `wall_time`, `cpu_time`, `gc_time`, `gc_overhead`, `max_rss_kb`, `allocations.*`, `collections.*`, `mean_latency`, `distr_latency`, `domain_stats`.
- `perf_<bench>....json` — JSONL, one per invocation. `perf stat` output: `task-clock`, `page-faults`, `cycles`, `instructions`.
- `olly.ndjson` / `perf.ndjson` — the run-level contract measurement streams (one line per invocation across the whole run; 760 lines each).
- `runbms.yml` — the resolved config (post-includes, post-overrides). What was actually run.
- `runbms_args.yml` — the CLI args running-ng was invoked with.

**Note on file size**

The stdout `.log` files (per-bench environment dumps, runbms output) are *not*
mirrored here — they carry no analysis-relevant data beyond the JSON sidecars.
They live in the original running-ng log dir if needed.
Original: `~/running-ng/gc-sweep-logs-5.5.0-fp-flambda-ermine-2026-08-20/ermine-2026-08-20-Thu-053154/`

**Run parameters**

- Host: ermine (ARM **Neoverse-N1**, 80 cores / 1 thread-per-core, governor=performance, 250 GiB, kernel 6.8.0-90-generic)
- Compilers: `ocaml-5.5.0` built stock / `--enable-frame-pointers` / `--enable-flambda` / both
- Tools: olly `0.5.4-12-g3d37a0b`, perf `6.8.12`; running-ng v0.3.8
- **38 benchmarks × 4 variants × N=5 — 760 invocations** (152 cells, 152 sidecar pairs)
- Run started 2026-08-20 05:31 (Thu). Four benchmarks (see below) were re-run at
  N=5 on 2026-08-23 after build/timeout fixes and merged in place.

**Benchmarks excluded**

- `goblint_gen_{default,large}` (macro-goblint) are **absent**: goblint's apron
  dependency needs `libmpfr-dev`, which is not installed on ermine (no sudo), so
  the binary did not build. That leaves **38** of the 40 ladder programs
  (`default_run` + `large_run` rungs).

**Re-run benchmarks**

Four benchmarks failed in the first pass and were re-run at N=5:

- `devkit_htmlstream_{default,large}` — the build hard-coded an x86_64 libevent
  path; ermine is aarch64, so it failed to link. Fixed to resolve the path via
  `pkg-config` at build time (multiarch), then rebuilt.
- `eio_conc_large`, `pplacer_like_large` — SIGKILLed at the old 120 s suite
  timeout on ermine (they run ~128 s / ~218 s here under olly+perf). The
  `macro-eio` / `macro-pplacer` suite timeouts were raised to 600 s and both
  re-run to completion.

**Allocation counters are clean here (in words).**
Unlike the 2026-07-24 monolith run — where OCaml 5.5.0's `Runtime_events` emitted
`EV_C_MINOR_ALLOCATED_WORDS` in *bytes* (~8× inflated) — this run's olly
(`0.5.4-12-g3d37a0b`) reports words: measured `minor_words / minor_collections`
= 0.99 × the minor-heap size. So `minor_words`, `promoted_words`,
`total_heap_words` and derived metrics are correct in this sweep.
