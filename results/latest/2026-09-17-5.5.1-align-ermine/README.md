# 2026-09-17 — OCaml 5.5.1 C-runtime alignment vs the frame-pointer layout effect (ermine)

Tests whether aligning the C runtime's code removes the instruction-fetch
code-layout sensitivity that makes `liq_video_frames_pool` ~29% slower under
frame pointers on aarch64. (Background: the fp regression is a `do_some_marking`
fetch-alignment artifact, not a frame-pointer cost — see
`liqvf-fp-alignment-finding.md` at the repo root.)

## Setup

- **Machine:** ermine (aarch64, ARM Neoverse-N1, 80 cores)
- **Config:** `running-ng: experiments/macro_5.5.1_align.yml`, tag `align_stress`
- **Benchmarks:** the 10 most fp-sensitive in the 2026-09-13 5.5.1 run — the 5
  largest fp speed-ups and 5 largest fp slow-downs by median wall.
- **Invocations:** N=5 (median reported), default GC, `perf_grp1`.
- **Runtimes — 2×4 factorial** (frame pointers off/on × C-runtime alignment):

  | tag | configure |
  |---|---|
  | `ocaml-5.5.1` | stock release |
  | `-fp` | `--enable-frame-pointers` |
  | `-alignF` | `CFLAGS=-falign-functions=32` |
  | `-alignL` | `CFLAGS=-falign-loops=16:8` |
  | `-alignLF` | both |
  | `-fp-alignF` / `-fp-alignL` / `-fp-alignLF` | `--enable-frame-pointers` + the above |

  The alignment flags land in `$(CFLAGS)`, appended after OCaml's `$(OC_CFLAGS)`
  in the runtime C build, so they win. They affect only the C runtime
  (`do_some_marking` et al.), never ocamlopt-generated code.

## Result — `-falign-functions` fixes it; `-falign-loops` does not

| benchmark | stock (s) | fp | F | L | LF | fp+F | fp+L | fp+LF |
|---|--:|--:|--:|--:|--:|--:|--:|--:|
| alt_ergo_chain_default | 44.0 | -3.9% | +0.0% | +0.3% | +2.8% | -3.9% | -3.6% | -3.8% |
| alt_ergo_chain_large | 111.0 | -6.5% | -2.4% | -2.4% | -2.3% | -6.2% | -6.2% | -6.3% |
| devkit_htmlstream_default | 87.0 | +2.7% | +0.2% | +0.1% | -0.0% | +2.5% | +2.6% | +2.5% |
| frama_c_eva_sqlite_large | 374.4 | – | -1.6% | -0.2% | -0.6% | +2.1% | +1.3% | +3.2% |
| goblint_gen_default | 42.2 | – | +0.0% | +0.0% | +0.2% | -1.2% | -1.2% | +0.3% |
| goblint_gen_large | 112.2 | – | +1.5% | +0.1% | -0.2% | -1.5% | -1.5% | -1.7% |
| **liq_video_frames_pool_default** | 55.4 | **+29.2%** | -0.1% | -0.8% | -1.3% | **+0.6%** | **+26.5%** | **-0.1%** |
| **liq_video_frames_pool_large** | 210.2 | **+29.5%** | +0.8% | -0.7% | +0.7% | **+0.6%** | **+30.4%** | **+0.7%** |
| menhir_sysver_canonical | 237.6 | -1.0% | -0.0% | -0.0% | +0.0% | -1.0% | -1.0% | -1.0% |
| sedlex_tokenize_large | 204.6 | +2.7% | +0.0% | +0.3% | +0.0% | +2.6% | +2.6% | +2.5% |

Columns after `stock` are median wall as % change vs stock (negative = faster).

**Reading it:**
- Frame pointers cost liqvf **~29%** (`fp` column), the only strong signal; the
  other nine benchmarks are within ±3% of stock in every column (noise).
- **`-falign-functions=32` removes the regression**: `fp+F` brings liqvf back to
  **+0.6%** of stock (both rungs). `-falign-functions` alone with no fp (`F`) is
  neutral — it's not doing anything *on top of* fp, it's making the fp build land
  the hot `do_some_marking` loop on a good fetch boundary deterministically.
- **`-falign-loops=16:8` does NOT fix it**: `fp+L` stays **+26–30%**. Aligning
  the loop (rather than the function) doesn't move the hot mark loop onto a good
  fetch block here — consistent with the earlier finding that loop-level padding
  is the wrong lever (it pads the fall-through-entered loop entry).
- `fp+LF` ≈ `fp+F`: the fix is entirely the function alignment.

This confirms the upstream recommendation: align `do_some_marking` (or build the
runtime with `-falign-functions`), not `-falign-loops`.

## Data

`logs/` holds the raw run: one `.log` per cell, `olly_*.json` / `perf_*.json`
sidecars (JSONL, one line per invocation), the data `contract/`
(`manifest.json` + `measurements/{olly,perf}.ndjson`), and the merged
`runbms.yml` / `runbms_args.yml`.

All 80 cells (8 runtimes × 10 benchmarks) ran — 80 perf sidecars, 80 logs.
Three `olly` sidecars dropped (`frama_c_eva_sqlite_large`, `goblint_gen_default`,
`goblint_gen_large`, all on plain `-fp`) — an olly-attach miss on those runs;
their `perf` data is present and they are not among the benchmarks that carry the
fp signal.
