#!/usr/bin/env bash
# Every helper in lib-portable.sh must produce byte-identical output to the GNU
# command it replaces. Run on Linux, where both are available, so the portable
# spelling is checked against the original rather than merely "looking right".
#
#   sh scripts/tests/test-lib-portable.sh
#
# On a BSD host the GNU comparisons are skipped and only the helpers run, which
# still catches a helper that fails outright there.
set -u
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT_DIR/scripts/lib-portable.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/libport.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1

pass=0; fail=0
ok()   { printf '  PASS  %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; fail=$((fail + 1)); }
same() { if cmp -s "$2" "$3"; then ok "$1"; else bad "$1"; diff "$2" "$3" | head -8; fi; }

# GNU sed -i takes no argument; BSD requires one. Detect rather than assume.
if printf 'x\n' > .probe && sed -i 's/x/y/' .probe 2>/dev/null; then
    HAVE_GNU_SED=1
else
    HAVE_GNU_SED=0
    echo "  (BSD sed detected: GNU comparisons skipped, helpers still exercised)"
fi

gnu() { [ "$HAVE_GNU_SED" = 1 ]; }

# --- insert_after, plain and with leading whitespace -------------------------
printf 'a\n(* libevent-based engine for lwt *)\nb\n' > in
cp in p; insert_after p 'libevent-based engine for lwt' 'type Lwt_engine.engine_id += Engine_id__libevent'
if gnu; then
    cp in g; sed -i '/libevent-based engine for lwt/a type Lwt_engine.engine_id += Engine_id__libevent' g
    same "insert_after vs sed '/re/a text'" g p
else
    grep -q 'Engine_id__libevent' p && ok "insert_after applied" || bad "insert_after"
fi

printf 'x\n  inherit Lwt_engine.abstract\ny\n' > in
cp in p; insert_after p 'inherit Lwt_engine.abstract' '  method id = Engine_id__libevent'
if gnu; then
    cp in g; sed -i '/inherit Lwt_engine.abstract/a\  method id = Engine_id__libevent' g
    same "insert_after preserves leading whitespace" g p
else
    grep -q '^  method id' p && ok "insert_after whitespace" || bad "insert_after whitespace"
fi

# --- delete_first_match: only the first, with two candidates present --------
printf 'l1\n (public_name ocamlformat)\nl3\n (public_name ocamlformat)\nl5\n' > in
cp in p; delete_first_match p '[(]public_name ocamlformat[)]'
if gnu; then
    cp in g; sed -i '0,/(public_name ocamlformat)/{/(public_name ocamlformat)/d}' g
    same "delete_first_match vs sed '0,/re/{/re/d}'" g p
fi
[ "$(grep -c 'public_name ocamlformat' p)" = 1 ] \
    && ok "delete_first_match leaves the second occurrence" \
    || bad "delete_first_match deleted too many"

# --- insert_at_line ----------------------------------------------------------
printf '#include <stdio.h>\nint main(){}\n' > in
cp in p; insert_at_line p 1 '#include <stdint.h>'
if gnu; then
    cp in g; sed -i '1a #include <stdint.h>' g
    same "insert_at_line vs sed '1a text'" g p
fi

# --- insert_after_offset: the N;N;N case, and offset 0 ----------------------
printf 'p0\nMATCH\nn1\nn2\nn3\ntail\n' > in
cp in p; insert_after_offset p 'MATCH' 3 'A1' 'A2' 'A3'
if gnu; then
    cp in g; sed -i '/MATCH/{
      N;N;N
      aA1\nA2\nA3
    }' g
    same "insert_after_offset vs sed '{N;N;N; a text}'" g p
fi

printf 'a\nMATCH\nb\n' > in
cp in p; insert_after_offset p 'MATCH' 0 'NEW'
if gnu; then
    cp in g; sed -i '/MATCH/a NEW' g
    same "insert_after_offset offset 0 equals a plain append" g p
fi

# --- sed_i -------------------------------------------------------------------
printf 'lang dune 3.24\nother\n' > in
cp in p; sed_i -E 's/lang dune 3\.2[0-9]+/lang dune 3.21/' p
if gnu; then
    cp in g; sed -i -E 's/lang dune 3\.2[0-9]+/lang dune 3.21/' g
    same "sed_i vs sed -i (-E substitution)" g p
fi
grep -q 'lang dune 3.21' p && ok "sed_i applied the substitution" || bad "sed_i"

printf 'x\n' > mode
chmod 754 mode
before="$(ls -l mode | cut -c1-10)"
sed_i 's/x/y/' mode
[ "$(ls -l mode | cut -c1-10)" = "$before" ] \
    && ok "sed_i preserves file mode" \
    || bad "sed_i changed the file mode"

# sed_i must not clobber the file when sed fails, which -i also would not.
printf 'keep\n' > survive
if sed_i 's/[/' survive 2>/dev/null; then
    bad "sed_i reported success on a bad script"
else
    [ "$(cat survive)" = "keep" ] \
        && ok "sed_i leaves the file intact when sed fails" \
        || bad "sed_i truncated the file on failure"
fi

# --- checksum and ncpu -------------------------------------------------------
printf 'hello\n' > c
sum="$(checksum c)"
case "$sum" in
    b1946ac92492d2347c6235b4d2611184) ok "checksum returns lowercase hex md5" ;;
    *) bad "checksum gave '$sum'" ;;
esac

n="$(ncpu)"
case "$n" in
    ''|*[!0-9]*) bad "ncpu gave '$n', not a number" ;;
    *) [ "$n" -ge 1 ] && ok "ncpu returns a positive integer ($n)" || bad "ncpu returned $n" ;;
esac

echo
echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ]
