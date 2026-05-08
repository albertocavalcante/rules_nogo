"""Analyzer bundles — curated sets organized by purpose and severity.

Bundles are plain Starlark lists of go_library labels. Compose them
with `+` and cherry-pick individual analyzers alongside them:

    deps = BUNDLE_CORRECTNESS + [
        "@rules_nogo//analyzers/bodyclose",
        "//tools/nogo/depguard",  # your own
    ]

Each bundle is a superset of the one above it in the safety hierarchy:

    BUNDLE_SAFETY       ⊂  BUNDLE_CORRECTNESS
    BUNDLE_CORRECTNESS  ≠  BUNDLE_STYLE (different concerns)
    BUNDLE_ALL          =  CORRECTNESS + STYLE + STATICCHECK + unused

┌─────────────────────────────────────────────────────────────────┐
│ BUNDLE_SAFETY — prevent crashes and undefined behavior          │
│                                                                 │
│  errcheck      unchecked errors → panics in production          │
│  ineffassign   dead assignments hiding real bugs                │
│  copylock      copying sync.Mutex → data races                  │
│  errorsas      wrong errors.As target → silent failures         │
│  lostcancel    leaked context → goroutine/resource leaks        │
├─────────────────────────────────────────────────────────────────┤
│ BUNDLE_CORRECTNESS — catch real bugs (includes SAFETY)          │
│                                                                 │
│  + exhaustive    non-exhaustive switch → missed cases           │
│  + noctx         http without context → can't cancel/trace      │
│  + nilaway       nil pointer analysis → prevent nil panics      │
│  + nilness       nil dereference paths                          │
│  + printf        format string mismatches → runtime panics      │
│  + httpresponse  unclosed http bodies → resource leaks          │
│  + stringintconv int-to-string gotcha (rune vs digit)           │
│  + unreachable   dead code after return/panic                   │
│  + unsafeptr     unsafe.Pointer misuse → memory corruption      │
├─────────────────────────────────────────────────────────────────┤
│ BUNDLE_STYLE — code quality (independent of CORRECTNESS)        │
│                                                                 │
│  bodyclose    unclosed response bodies                          │
│  structtag    malformed struct tags → silent json/db bugs       │
│  unmarshal    wrong unmarshal targets                            │
│  unusedresult discarded pure-function returns                   │
│  stdmethods   wrong signatures on Error/String/etc              │
│  sigchanyzer  unbuffered signal channel → missed signals        │
├─────────────────────────────────────────────────────────────────┤
│ BUNDLE_STATICCHECK — all SA + S1 + ST codes (~145 checks)       │
│                                                                 │
│  SA: correctness & performance (sa1000–sa9009)                  │
│  S1: code simplification (s1000–s1040)                          │
│  ST: style conventions (st1000–st1023)                          │
│                                                                 │
│  Cherry-pick with staticcheck_analyzers():                      │
│    staticcheck_analyzers(SA_CODES + ["-sa4023"])                 │
├─────────────────────────────────────────────────────────────────┤
│ BUNDLE_ALL — everything above + unused                          │
└─────────────────────────────────────────────────────────────────┘

NOTE: nogo has no warning mode — ALL findings fail the build.
If you need gradual rollout, start with BUNDLE_SAFETY and grow.
The warning_mode.patch for rules_go adds per-analyzer severity
levels (see PATCHING.md).
"""

# ── Staticcheck code lists ───────────────────────────────────────────
# These lists define which codes exist. Use staticcheck_analyzers() from
# defs.bzl to convert them to labels with exclusion support.

# SA: correctness and performance (bugs, panics, perf traps)
SA_CODES = [
    "sa1000", "sa1001", "sa1002", "sa1003", "sa1004", "sa1005",
    "sa1006", "sa1007", "sa1008", "sa1010", "sa1011", "sa1012", "sa1013",
    "sa1014", "sa1015", "sa1016", "sa1017", "sa1018", "sa1019", "sa1020",
    "sa1021", "sa1023", "sa1024", "sa1025", "sa1026", "sa1027", "sa1028",
    "sa1029", "sa1030", "sa1031", "sa1032",
    "sa2000", "sa2001", "sa2002", "sa2003",
    "sa3000", "sa3001",
    "sa4000", "sa4001", "sa4003", "sa4004", "sa4005", "sa4006", "sa4008",
    "sa4009", "sa4010", "sa4011", "sa4012", "sa4013", "sa4014", "sa4015",
    "sa4016", "sa4017", "sa4018", "sa4019", "sa4020", "sa4021", "sa4022",
    "sa4023", "sa4024", "sa4025", "sa4026", "sa4027", "sa4028", "sa4029",
    "sa4030", "sa4031", "sa4032",
    "sa5000", "sa5001", "sa5002", "sa5003", "sa5004", "sa5005", "sa5007",
    "sa5008", "sa5009", "sa5010", "sa5011", "sa5012",
    "sa6000", "sa6001", "sa6002", "sa6003", "sa6005", "sa6006",
    "sa9001", "sa9002", "sa9003", "sa9004", "sa9005", "sa9006", "sa9007",
    "sa9008", "sa9009",
]

# S1: simplification (cleaner idioms, fewer lines)
S1_CODES = [
    "s1000", "s1001", "s1002", "s1003", "s1004", "s1005",
    "s1006", "s1007", "s1008", "s1009", "s1010", "s1011", "s1012",
    "s1016", "s1017", "s1018", "s1019", "s1020", "s1021", "s1023", "s1024",
    "s1025", "s1028", "s1029", "s1030", "s1031", "s1032", "s1033",
    "s1034", "s1035", "s1036", "s1037", "s1038", "s1039", "s1040",
]

# ST: style (naming, comments, conventions)
ST_CODES = [
    "st1000", "st1001", "st1003", "st1005", "st1006",
    "st1008", "st1011", "st1012", "st1013", "st1015", "st1016",
    "st1017", "st1018", "st1019", "st1020", "st1021", "st1022", "st1023",
]

# ── BUNDLE_SAFETY ────────────────────────────────────────────────────
# Minimum: prevents crashes, data races, and resource leaks.
# Start here if you're adding nogo to an existing codebase.
BUNDLE_SAFETY = [
    "@rules_nogo//analyzers/errcheck",       # unchecked errors
    "@rules_nogo//analyzers/ineffassign",     # dead assignments
    "@rules_nogo//analyzers/stdlib/copylock",    # sync.Mutex copy
    "@rules_nogo//analyzers/stdlib/errorsas",    # errors.As misuse
    "@rules_nogo//analyzers/stdlib/lostcancel",  # context leak
]

# ── BUNDLE_CORRECTNESS ──────────────────────────────────────────────
# Real bugs: includes everything in SAFETY plus deeper checks.
# Recommended for production codebases.
#
# NOTE: vet=True (default in our nogo() wrapper) already provides
# atomic, bools, buildtag, nilfunc, printf. These are intentionally
# excluded from all bundles to avoid "duplicate analyzer" errors.
BUNDLE_CORRECTNESS = BUNDLE_SAFETY + [
    "@rules_nogo//analyzers/exhaustive",         # non-exhaustive switch
    "@rules_nogo//analyzers/noctx",              # http without context
    "@rules_nogo//analyzers/nilaway",            # nil pointer analysis
    "@rules_nogo//analyzers/stdlib/nilness",        # nil dereference
    "@rules_nogo//analyzers/stdlib/httpresponse",   # unclosed bodies
    "@rules_nogo//analyzers/stdlib/stringintconv",  # int→string gotcha
    "@rules_nogo//analyzers/stdlib/unreachable",    # dead code
    "@rules_nogo//analyzers/stdlib/unsafeptr",      # unsafe.Pointer
]

# ── BUNDLE_STYLE ─────────────────────────────────────────────────────
# Code quality: independent of CORRECTNESS (different concerns).
# Add alongside CORRECTNESS, not instead of it.
BUNDLE_STYLE = [
    "@rules_nogo//analyzers/bodyclose",          # unclosed http bodies
    "@rules_nogo//analyzers/stdlib/structtag",      # malformed tags
    "@rules_nogo//analyzers/stdlib/unmarshal",      # wrong unmarshal
    "@rules_nogo//analyzers/stdlib/unusedresult",   # discarded returns
    "@rules_nogo//analyzers/stdlib/stdmethods",     # wrong Error/String sig
    "@rules_nogo//analyzers/stdlib/sigchanyzer",    # unbuffered signal chan
]

# ── BUNDLE_STATICCHECK ──────────────────────────────────────────────
# All staticcheck SA + S1 + ST codes (~145 checks).
# For cherry-picking, use staticcheck_analyzers() instead:
#   staticcheck_analyzers(SA_CODES + ["-sa4023", "-sa9003"])
BUNDLE_STATICCHECK = [
    "@rules_nogo//analyzers/staticcheck:" + code
    for code in SA_CODES + S1_CODES + ST_CODES
]

# ── BUNDLE_ALL ───────────────────────────────────────────────────────
# Everything: CORRECTNESS + STYLE + STATICCHECK + unused.
# The kitchen sink — use when your codebase is clean enough to pass
# all ~170 checks. Start with BUNDLE_CORRECTNESS and grow into this.
BUNDLE_ALL = BUNDLE_CORRECTNESS + BUNDLE_STYLE + BUNDLE_STATICCHECK + [
    "@rules_nogo//analyzers/unused",
]
